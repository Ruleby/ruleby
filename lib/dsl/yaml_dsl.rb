
require 'ruleby'
require 'dsl/letigre'
module Ruleby
  module YamlDsl
    require 'yaml'
    def self.load_rules(rules_yaml, engine)
      ry = YAML::load(rules_yaml)
      ry.each do |k,v|
        if k =~ /_rule/
          wh = v['when']
          wh.gsub!('@', '#')
          wh = wh.split(',')
          th = v['then']
          priority = v['priority']
          th = "context engine -> #{th}"       
          r = LeTigre::RulebookHelper.new engine
          r.rule k, { :priority => priority }, *wh, &th.to_proc
        end
      end
    end
  end
end