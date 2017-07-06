require 'json'
require 'bigdecimal'
module CacheStore
  class Marshal

    def dump(object, json = true)
      hash = {}
      hash['class'] = object.class
      if object.is_a?(Array)
        hash['items'] = []
        object.each do |a|
          hash['items'] << dump(a, false)
        end
      elsif object.is_a?(Hash)
        hash['items'] = []
        object.each do |key, value|
          hash['items'] << { 'key' => key, 'value' => dump(value, false) }
        end
      elsif object.instance_variables.length > 0 && ![Date, DateTime,Time].include?(object.class)
        object.instance_variables.each do |v|
          hash['attributes'] << { 'key' => v, 'value' => dump(object.instance_variable_get(v), false) }
        end
      else
        if hash['class'] == Time
          hash['value'] = object.to_f
        elsif hash['class'] == Date
          hash['value'] = object.to_s
        elsif hash['class'] == DateTime
          hash['value'] = object.to_time.to_i
        else
          hash['value'] = object
        end
      end

      if json
        JSON.dump(hash)
      else
        hash
      end
    end

    def get_attributes(object)
      object.instance_variables
    end

    def load(object, json=true)
      if json
        so = JSON.parse(object)
      else
        so = object
      end

      if so['class'] == 'Array'
        so['items'].map { |i| load(i) }
      elsif so['class'] == 'Hash'
        hash = {}
        so['items'].each do |i|
          hash[i['key']] = load(i['value'], false)
        end
        hash
      elsif so['attributes'] != nil
        obj = Object.const_get(so['class']).new
        so['attributes'].each do |a|
          obj.instance_variable_set(a[:key], load(a['value'], false))
        end
        obj
      else
        parse(type: Object.const_get(so['class']), value: so['value'])
      end
    end

    def parse(type:, value:)
      if type == Time
        if value.is_a?(Time)
          value
        elsif value.is_a?(Integer) || value.is_a?(Float)
          Time.at(BigDecimal.new(value.to_s))
        else
          Time.parse(value)
        end
      elsif type == Date
        if value.is_a?(Date)
          value
        elsif value.is_a?(Integer) || value.is_a?(Float)
          Date.at(value)
        else
          Date.parse(value)
        end
      elsif type == DateTime
        if value.is_a?(DateTime)
          value
        elsif value.is_a?(Integer)
          DateTime.strptime(value.to_s,'%s')
        else
          DateTime.parse(value)
        end
      elsif type == :bool
        if value == true || value == false
          value
        elsif(/(true|t|yes|y|1)$/i === value.to_s.downcase)
          true
        elsif (/(false|f|no|n|0)$/i === value.to_s.downcase)
          false
        elsif value != nil
          raise 'Unable to parse bool'
        end
      elsif type == TrueClass
        true
      elsif type == FalseClass
        false
      elsif type == Integer || type == Fixnum
        Integer(value)
      elsif type == Float
        Float(value)
      elsif type == BigDecimal
        if value.is_a?(BigDecimal)
          value
        else
          value = value.to_s
          raise 'Unable to parse BigDecimal' unless value =~ /\A-?\d+(\.\d*)?/
          BigDecimal(value)
        end
      elsif type == String
        String(value)
      elsif type == Regexp
        Regexp.new(value)
      elsif type == String
        value
      elsif type == nil
        nil
      else
        binding.pry
        raise 'Unable to parse'
      end
    rescue => e
      raise 'InvalidParseValueError',
            "Unable to parse value: #{value} into type: #{type}. Error: #{e}"
    end

  end
end