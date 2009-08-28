module KingFormat
  # a little rewrite of the rails internal number helper with better:
  # - rounding
  # - detecting money symbol / money string
  # -
  module MoneyHelper

    # returns the keys from money symbols als Hash{array} for select options 
    def money_selects
      money_symbols.keys.sort
    end

    # ==== Returns
    # Hash with currency as keys and formatting options as sub hash
    # { 'EUR' => {:unit=>'€', :format => '%n %u', :precision=> '2',:delimiter=>'.', :separator=>','},
    #   'USD' => {:unit=>'$'}
    def money_symbols
      @money_symbols ||= begin
        eur = {:format => '%n %u', :precision=> '2',:delimiter=>'.', :separator=>','}
        dol = {:format => '%n %u', :precision=> '2',:delimiter=>',', :separator=>'.'}
        {
        'EUR' => eur.merge(:unit=>'€'),
        'GBP' => dol.merge(:unit=>'£'),
        'JPY' => dol.merge(:unit=>'¥'),
        'USD' => dol.merge(:unit=>'$'),
        'AUD' => dol.merge(:unit=>'$'),
        'CAD' => dol.merge(:unit=>'$'),
        'HKD' => dol.merge(:unit=>'$'),
        'SGD' => dol.merge(:unit=>'$'),
        'AED' => nil,
        'BGN' => nil,
        'CZK' => nil,
        'DKK' => nil,
        'EEK' => nil,
        'HUF' => nil,
        'LTL' => nil,
        'LVL' => nil,
        'PLN' => nil,
        'RON' => nil,
        'SEK' => nil,
        'SKK' => nil,
        'CHF' => nil,
        'ISK' => nil,
        'NOK' => nil,
        'HRK' => nil,
        'RUB' => nil,
        'TRY' => nil,
        'BRL' => nil,
        'CNY' => nil,
        'IDR' => nil,
        'KRW' => nil,
        'MXN' => nil,
        'MYR' => nil,
        'NZD' => nil,
        'PHP' => nil,
        'THB' => nil,
        'ZAR' => dol.merge(:unit=>'R')
      }
      end
    end
   
  end
end