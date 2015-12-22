module TDJobs
  class HashQuery

    ALLOWED = [:$OR, :$AND]

    # Takes a Hash with attributes containing custom filters to search a Job in the given set.
    #   It first will build the string query according to the paramters given using the .build_query
    #   method. After that, it will inject all corresponding parameters in the query, applying it to
    #   the given set of items (:results).
    # @param results [Job::ActiveRecord_Relation] ActiveRecord_Relation of jobs where the search
    #   will be applied.
    # @param parameters [Hash] all filters that should the result jobs meet.
    # @return [Job::ActiveRecord_Relation] ActiveRecord_Relation of jobs containing all jobs that
    #   meet the filters given in 'parameters'.
    # @raise [TDJobs::InvalidQuery] if the parameters have an invalid metadata field or if an
    #   invalid modifier was used.
    def self.process_hash(results, parameters)
      query_utils = self.build_query(parameters, [])
      query_text = query_utils.first
      query_params = query_utils.second
      results.where(query_text, *query_params)
    end

    # Recursively builds an SQL query according to the :parameters given.
    # @param parameters [Hash] hash representing the filters in the current depth of recursion.
    # @param base [Array] list of parent attributes or keys for the current depth of recursion.
    # @param assoc [String] binary association operation to be used for all childs of the current
    #   level of recursion. Can be either 'AND' or 'OR'.
    # @return [Array] An array of two elements, where the first position is the query ready to be
    #   parametrized. The second element is an array of parameters to be injected in the query.
    # @raise [TDJobs::InvalidQuery] if some parameter is not allowed or malformed.
    def self.build_query(parameters, base, assoc = 'AND')
      query_text = ""
      injections = []
      parameters.each do |key, value|
        query_text += " #{assoc} " unless query_text.empty?
        if key.to_sym == :$or
          sub_response = self.handle_association(value, base, :OR)
          injections.concat(sub_response.second)
          query_text += "(#{sub_response.first})"
        elsif key.to_sym == :$and
          sub_response = self.handle_association(value, base, :AND)
          injections.concat(sub_response.second)
          query_text += "(#{sub_response.first})"
        elsif value.is_a?(String) || value.is_a?(Fixnum) || value.is_a?(Float)
          prefix = self.build_prefix(base, key)
          query_text += "#{prefix} = ?"
          injections.concat(base.values_at(1..-1))
          injections.push(key) if base.any?
          injections.push(value)
        elsif value.is_a?(Hash)
          value.each_with_index do |(modifier, condition), index|
            query_text += " #{assoc} " unless index == 0
            if self.operator?(modifier)
              prefix = self.build_prefix(base, key)
              query_text += "#{prefix} #{operator(modifier)} (?)"
              injections.concat(base.values_at(1..-1))
              injections.push(key) if base.any?
              injections.push(self.setup_condition(modifier, condition))
            else
              new_params = {}
              new_params[modifier] = condition
              sub_response = self.build_query(new_params, base.dup.push(key), assoc)
              injections.concat(sub_response.second)
              query_text += "(#{sub_response.first})"
            end
          end
        end
      end
      injections = self.stringify_non_array_items(injections)
      ["#{query_text}", injections]
    end

    # Converts all non-array elements of the given array to a string. Uses the #to_s method in each
    #   applicable element.
    # @param array [Array] Collection of elements to be converted.
    # @return [Array] Collection of elements converted.
    def self.stringify_non_array_items(array)
      array.map do |inj|
        unless inj.is_a?(Array) then inj.to_s
        else inj
        end
      end
    end

    # Determines whether the given string is an operator in @symbols or not.
    # @param op [String] string to be tested.
    # @return [Boolean] True if the given :op is a valid operator, false otherwise.
    def self.operator?(op)
      begin
        operator(op)
        true
      rescue TDJobs::InvalidQuery
        false
      end
    end

    # Takes a list of base keys or attributes and a leaf key, builds and return the corresponding
    #   Postgres query. (This is used when querying in JSON fields).
    # @param base_keys [Array] A list of parent keys for the specific field.
    # @param key [String] Last key of the required field.
    # @return [String] A chained string represented a query for the given field ready to be injected
    #   with specific parameters.
    # @example Querying a JSON field.
    #   :base_keys = ["metadata", "contact", "phone"]
    #   :key = "international"
    #   will return:
    #   => "metadata -> ? -> ? ->> ?"
    # @example A non-parent query.
    #   :base_keys = []
    #   :key = "status"
    #   will return:
    #   => "status"
    def self.build_prefix(base_keys, key)
      result = ""
      base_keys.each_with_index do |base, index|
        result += index == 0 ? "#{base}" : "?"
        result += (index == base_keys.count - 1 ? " ->> " : " -> ")
      end
      result += base_keys.any? ? "?" : "#{key}"
    end

    # Receives a logical operator and applies filters to the Hash of expressions given, associating
    #   results by the given operator.
    # @param parameters [Hash] Hash of expressions that wants to be associated using the specified
    #   operator.
    # @param base [Array] list of parent attributes or keys for the current query parameters.
    # @param association [String] Can be either 'OR' or 'AND', meaning which operator will be used
    #   to associate the given expressions.
    # @return [Array] An array of two elements, where the first position is the query ready to be
    #   parametrized. The second element is an array of parameters to be injected in the query.
    # @raise [TDJobs::InvalidQuery] if the given :parameters Hash is invalid.
    # @raise [TDJobs::InvalidQuery] if the given :association is not allowed.
    def self.handle_association(parameters, base, association)
      unless parameters.is_a?(Hash)
        raise TDJobs::InvalidQuery,
              'When using an association, you should specify an Hash with expressions to '\
              'be filtered.'
      end
      allowed = ALLOWED.map { |operator| operator[1..-1] } # :$OR => 'OR'
      unless allowed.include?(association.upcase.to_s)
        raise TDJobs::InvalidQuery,
              "Invalid association operator (#{association}). Valid ones are: #{allowed.join(', ')}"
      end
      self.build_query(parameters, base, association)
    end

    # Creates, ONLY ONCE, a list of valid modifiers and their associated operator symbol, returning
    # the symbol corresponding to the given modifier.
    # @param modifier [String or Symbol] the contraction of the required modifier symbol.
    # @return [String] the symbol associated with 'modifier'.
    # @raise [TDJobs::InvalidQuery] if the given modifier doesn't exist in the valid list.
    def self.operator(modifier)
      modifier = modifier.to_s
      unless @symbols
        @symbols = {}
        @symbols[:gt]  = ">";  @symbols[:lt]   = "<";    @symbols[:geq] = ">="
        @symbols[:leq] = "<="; @symbols[:like] = "LIKE"; @symbols[:in]  = "IN"
        @symbols.stringify_keys!
      end
      unless @symbols[modifier]
        raise TDJobs::InvalidQuery, "'#{modifier}' is not included in the valid modifiers "\
                                      "(#{@symbols.keys.join(', ')})."
      end
      @symbols[modifier]
    end

    # Sets up the given condition so that the ActiveRecord query is correct.
    # @param modifier [String] the modifier that will be used in the query.
    # @param condition condition to be used in the query.
    # @return the appropiated form of the condition according to the modifier.
    # @raise [TDJobs::InvalidQuery] if the modifier is being used with a wrong condition type.
    def self.setup_condition(modifier, condition)
      return case modifier.to_sym
      when :like then "%#{condition}%"
      when :in
        unless condition.is_a?(Array)
          raise TDJobs::InvalidQuery,
                "Please use an Array with all possible values for 'in' condition"
        end
        all_string = true
        condition.each { |element| all_string &= element.is_a?(String) }
        unless all_string
          raise TDJobs::InvalidQuery,
                "All elements inside the Array for 'in' condition must be Strings"
        end
        condition
      else
        if condition.is_a?(Array) || condition.is_a?(Hash)
          raise TDJobs::InvalidQuery,
                "You can't use '#{modifier}' to compare the #{condition.class} type"
        end
        "#{condition}"
      end
    end

    # Converts from String to Hash the representation of a JSON with filters for a Job search,
    #   doesn't allow resulting Hash to have attributes that doesn't correspond to a Job column.
    # @param query [String] string representation of attributes to be converted and filtered.
    # @return [Hash] all valid attributes in a Hash with their respective values.
    # @raise [TDJobs::InvalidQuery] if invalid attributes were given or no attributes were given.
    def self.job_query(query)
      raise TDJobs::InvalidQuery, 'Job filter not given.' if query.nil?
      query_hash = JSON.parse(query)
      invalid_keys = []
      query_hash.each do |key, value|
        unless Job.column_names.include?(key.to_s) || ALLOWED.include?(key.upcase.to_sym)
          invalid_keys.push(key)
        end
      end
      unless invalid_keys.empty?
        raise TDJobs::InvalidQuery,
              "The following filter parameters are not valid: (#{invalid_keys.join(", ")})"
      end
      raise TDJobs::InvalidQuery, "No parameters to filter given." if query_hash.empty?
      query_hash
    end
  end
end
