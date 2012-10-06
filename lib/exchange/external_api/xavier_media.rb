module Exchange
  module ExternalAPI
    
    # The XavierMedia API class, handling communication with the Xavier Media Currency API
    # You can find further information on the Xaviermedia API here: http://www.xavierforum.com/viewtopic.php?f=5&t=10979&sid=671a685edbfa5dbec219fbc6793d5057
    # @author Beat Richartz
    # @version 0.1
    # @since 0.1
    #
    class XavierMedia < XML
      
      # The base of the Xaviermedia API URL
      API_URL              = "http://api.finance.xaviermedia.com/api"
      # The currencies the Xaviermedia API URL can handle
      CURRENCIES           = %W(eur usd jpy gbp cyp czk dkk eek huf ltl mtl pln sek sit skk chf isk nok bgn hrk rol ron rub trl aud cad cny hkd idr krw myr nzd php sgd thb zar)
      
      # Updates the rates by getting the information from Xaviermedia API for today or a defined historical date
      # The call gets cached for a maximum of 24 hours.
      # @version 0.3
      # @param [Hash] opts Options to define for the API Call
      # @option opts [Time, String] :at a historical date to get the exchange rates for
      # @example Update the currency bot API to use the file of March 2, 2010
      #   Exchange::ExternalAPI::XavierMedia.new.update(:at => Time.gm(3,2,2010))
      #
      def update(opts={})
        time       = Exchange::Helper.assure_time(opts[:at], :default => :now)
        api_url    = api_url(time)
        
        Call.new(api_url, api_opts(opts.merge(:at => time))) do |result|
          @base                 = extract_base_currency result
          @rates                = extract_rates result
          @timestamp            = extract_timestamp result
        end
      end
      
      private
      
        # A helper function which build a valid api url for the specified time
        # @param [Time] time The exchange rate date for which the URL should be built
        # @return [String] An Xaviermedia API URL for the specified time
        #
        def api_url(time)
          [API_URL, "#{time.strftime("%Y/%m/%d")}.xml"].join('/')
        end
        
        # Options for the API call to make
        # @param [Hash] opts The options to generate the call options with
        # @option opts [Time, String] :at a historical date to get the exchange rates for
        # @return [Hash] The options hash for the API call
        #
        def api_opts(opts={})
          retry_urls = Exchange.configuration.api.retries.times.map{ |i| api_url(opts[:at] - 86400 * (i+1)) }
          
          { :format => :xml, :at => opts[:at], :retry_with => retry_urls }
        end
        
        # Extract a timestamp of the callresult
        # @param [Nokogiri::XML] result the callresult
        # @return [Integer] A unix timestamp
        #
        def extract_timestamp(result)
          Time.gm(*result.css('fx_date').children[0].to_s.split('-')).to_i
        end
        
        # Extract rates from the callresult
        # @param [Nokogiri::XML] result the callresult
        # @return [Hash] A hash with currency / rate pairs
        #
        def extract_rates(result)
          Hash[*result.css('fx currency_code').children.map(&:to_s).zip(result.css('fx rate').children.map{|c| BigDecimal.new(c.to_s) }).flatten]
        end
        
        # Extract the base currency from the callresult
        # @param [Nokogiri::XML] result the callresult
        # @return [String] The base currency for the rates
        #
        def extract_base_currency(result)
          result.css('basecurrency').children[0].to_s
        end
        
    end
  end
end