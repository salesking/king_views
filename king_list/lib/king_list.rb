# KingList
# You need:
# KingFormat Plugin for the table helper
# - haml
# - I18n 
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require "king_list/overrides"
require "king_list/list_helper"
require "king_list/app_helper"
require "king_list/builder/table"
require "king_list/builder/show"


# extend AC with our helper module
ActionController::Base.helper KingList::ListHelper

# Helper Functions used in application controller, which should be extracted a little more 
ActionController::Base.helper KingList::AppHelper
