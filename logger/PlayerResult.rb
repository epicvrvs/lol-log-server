require 'nil/symbol'

require_relative 'LogObject'

class PlayerResult
  include SymbolicAssignment

  Mapping = {
    leaves: :leaves,
    level: :summonerLevel,
    losses: :losses,
    summonerName: :name,
    skinName: :champion,
    userId: :id,
    wins: :wins,
  }

  StatMapping = {
    'MINIONS_KILLED' => :minionsKilled,
    'PHYSICAL_DAMAGE_TAKEN' => :physicalDamageTaken,
    'PHYSICAL_DAMAGE_DEALT_PLAYER' => :physicalDamageDealt,
    'TOTAL_HEAL' => :amountHealed,
    'ASSISTS' => :assists,
    'GOLD_EARNED' => :gold,
    'LARGEST_CRITICAL_STRIKE' => :largestCriticalStrike,
    'MAGIC_DAMAGE_DEALT_PLAYER' => :magicalDamageDealt,
    'LARGEST_MULTI_KILL' => :largestMultiKill,
    'BARRACKS_KILLED' => :barracksDestroyed,
    'LEVEL' => :level,
    'LARGEST_KILLING_SPREE' => :longestKillingSpree,
    'TOTAL_TIME_SPENT_DEAD' => :timeSpentDead,
    'NEUTRAL_MINIONS_KILLED' => :neutralMinionsKilled,
    'MAGIC_DAMAGE_TAKEN' => :magicalDamageTaken,
    'TURRETS_KILLED' => :turretsDestroyed,
    'NUM_DEATHS' => :deaths,
    'CHAMPIONS_KILLED' => :kills,
    'ITEM0' => :item0,
    'ITEM1' => :item1,
    'ITEM2' => :item2,
    'ITEM3' => :item3,
    'ITEM4' => :item4,
    'ITEM5' => :item5,
  }

  attr_reader :victorious

  def initialize(array)
    root = LogObject.new(nil, nil, array)
    Mapping.each do |sourceSymbol, destinationSymbol|
      value = root.get(sourceSymbol)
      setMember(destinationSymbol, value)
    end

    statistics = {}
    root.get(:statistics, :list, :source).each do |entry|
      entry = LogObject.new(nil, nil, entry)
      name = entry.get(:statTypeName)
      value = entry.get(:value)
      statistics[name] = value
    end

    StatMapping.each do |statName, destinationSymbol|
      if !statistics.has_key?(statName)
        #not consistently available
        if ['BARRACKS_KILLED', 'TURRETS_KILLED'].include?(statName)
          value = nil
        else
          raise "Unable to find a stats entry for #{statName.inspect}"
        end
      end
      value = statistics[statName]
      setMember(destinationSymbol, value)
    end
    @victorious = statistics['LOSE'] == nil
  end

  def getDatabaseFields
    return {
      summoner_name: @name,
      summoner_level: @summonerLevel,

      wins: @wins,
      leaves: @leaves,
      losses: @losses,

      champion: @champion,
      champion_level: @level,

      kills: @kills,
      deaths: @deaths,
      assists: @assists,

      minions_killed: @minionsKilled,
      neutral_minions_killed: @neutralMinionsKilled,

      gold: @gold,

      physical_damage_dealt: @physicalDamageDealt,
      physical_damage_taken: @physicalDamageTaken,

      magical_damage_dealt: @magicalDamageDealt,
      magical_damage_taken: @magicalDamageTaken,

      amount_healed: @amountHealed,

      turrets_destroyed: @turretsDestroyed,
      barracks_destroyed: @barracksDestroyed,

      largest_critical_strike: @largestCriticalStrike,
      largest_multikill: @largestMultiKill,
      longest_killing_spree: @longestKillingSpree,

      time_spent_dead: @timeSpentDead,

      item0: @item0,
      item1: @item1,
      item2: @item2,
      item3: @item3,
      item4: @item4,
      item5: @item5,
    }
  end
end
