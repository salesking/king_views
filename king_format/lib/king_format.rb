require 'active_support/deprecation'
# KingFormat
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

# AR model extension to define money / percent fields
require 'model_mixins/has_percent_fields'
require 'model_mixins/has_money_fields'
require 'model_mixins/has_date_fields'

require 'helpers/formatting_helper'
ActionController::Base.helper KingFormat::FormattingHelper
require 'helpers/date_helper' # holding date functions
ActionController::Base.helper KingFormat::DateHelper
require 'helpers/money_helper' # holding money symbols
ActionController::Base.helper KingFormat::MoneyHelper