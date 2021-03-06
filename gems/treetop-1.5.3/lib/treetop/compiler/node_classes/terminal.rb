module Treetop
  module Compiler    
    class Terminal < AtomicExpression
      def compile(address, builder, parent_expression = nil)
        super
	# Handle modifiers:
	insensitive = modifiers.text_value.include? 'i'
	re = modifiers.text_value.include? 'r'
	if re
	  grounded_regexp = "#{('\A'+eval(string)).inspect}"
	  cache_key = "'__#{modifiers.text_value}__'+(gr = #{grounded_regexp})"
	  re_modifiers = "#{insensitive ? 'Regexp::IGNORECASE' : 0}"
	  str = "@regexps[#{cache_key}] ||= Regexp.new(gr, #{re_modifiers})"
	  mode = ':regexp'
	elsif insensitive
	  str = string.downcase
	  string_length = eval(str).length
	  mode = ':insens'
	else
	  str = string
	  string_length = eval(str).length
	  mode = 'false'
	end

        builder.if__ "(match_len = has_terminal?(#{str}, #{mode}, index))" do
          if address == 0 || decorated? || mode != 'false' || string_length > 1
	    assign_result "instantiate_node(#{node_class_name},input, index...(index + match_len))"
	    extend_result_with_inline_module
          else
            assign_lazily_instantiated_node
	  end
          builder << "@index += match_len"
        end
        builder.else_ do
          builder << "terminal_parse_failure(#{string})"
          assign_result 'nil'
        end
      end
    end
  end
end
