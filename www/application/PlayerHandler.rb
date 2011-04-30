require 'nil/string'

require 'www-library/RequestHandler'

require 'application/SiteContainer'
require 'application/error'
require 'application/ChampionPerformance'

require 'visual/PlayerHandler'

class PlayerHandler < SiteContainer
  attr_reader :playerHandler

  SortableColumns = [
    'champion',
    'gameCount',
    'winRatio',
    'killsPerGame',
    'deathsPerGame',
    'assistsPerGame',
    'champion.killsPerDeath',
    'killsAndAssistsPerDeath',
    'minionsKilledPerGame',
    'neutralMinionsKilledPerGame',
    'goldPerGame',
  ]

  def installHandlers
    @playerHandler = WWWLib::RequestHandler.handler('player', method(:viewPlayer), 1..2)
    addHandler(@playerHandler)
  end

  def nanHack
    NaN
  end

  def viewPlayer(request)
    arguments = request.arguments
    playerIdString = arguments.first
    if !playerIdString.isNumber
      argumentError
    end
    sortingString = arguments.size == 1 ? SortableColumns.first : arguments[1]
    sortableIndex = SortableColumns.index(sortingString)
    if sortableIndex == nil
      argumentError
    end
    playerId = playerIdString.to_i
    result = @database[:player_result].select(:summoner_name).where(user_id: playerId).limit(1).all
    if result.empty?
      argumentError
    end
    playerName = result.first[:summoner_name]
    title = playerName
    defeats = getPlayerPerformance(playerId, :defeated_team_id)
    victories = getPlayerPerformance(playerId, :victorious_team_id)
    championData = {}
    sortByChampion(defeats, championData, false)
    sortByChampion(victories, championData, true)
    championData.each do |key, value|
      setChampionColumns(value)
    end
    championData = championData.values.sort do |x, y|
      translate = lambda do |container, index|
        input = container.columns[index]
        if input.class == Float && (input.nan? || input.infinite?)
          -1.0
        else
          input
        end
      end
      left = translate.call(x, sortableIndex)
      right = translate.call(y, sortableIndex)
      if left.class == String
        left <=> right
      else
        - (left <=> right)
      end
    end
    content = renderPlayer(playerName, playerId, defeats, victories, championData)
    return @generator.get(content, request, title)
  end

  def getPlayerPerformance(playerId, teamSymbol)
    return @database[:game_result].left_outer_join(:team_player, team_id: teamSymbol).left_outer_join(:player_result, id: :player_id).where(user_id: playerId).all
  end

  def sortByChampion(games, championData, isVictory)
    games.each do |game|
      performance = ChampionPerformance.new(game, isVictory)
      key = performance.champion
      if championData[key] == nil
        championData[key] = performance
      else
        championData[key].combine(performance)
      end
    end
  end
end
