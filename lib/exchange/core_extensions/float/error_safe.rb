# -*- encoding : utf-8 -*-
module Exchange
  
  # Make Floating Points forget about their incapabilities when dealing with money
  #
  module ErrorSafe
    
    # Installs a method chain that overwrites the old error prone meth with the new one
    #
    def self.money_error_preventing_method_chain base, meth
      base.send :alias_method, :"#{meth}_with_errors", meth
      base.send :alias_method, meth, :"#{meth}_without_errors"
    end
    
    # @!macro prevent_errors_with_exchange_for
    #   Prevents float errors when dealing with instances of Exchange::Money
    #   By Typecasting the float into a Big Decimal
    #   @method $1(other)
    #
    def self.prevent_errors_with_exchange_for base, meth
      base.send(:define_method, :"#{meth}_without_errors", lambda { |other|
        if other.is_a?(Exchange::Money)
          BigDecimal(self.to_s).send(meth, other.value).to_f
        else
          send(:"#{meth}_with_errors", other)
        end
      })
      money_error_preventing_method_chain base, meth
    end
    
    def self.included base
      %W(* / + -).each do |meth|
        
        # @macro prevent_errors_with_exchange_for
        #
        prevent_errors_with_exchange_for base, meth.to_sym
        
      end
    end
    
  end
  
end

Float.send(:include, Exchange::ErrorSafe)
