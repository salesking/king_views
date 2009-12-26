require "#{File.dirname(__FILE__)}/king_form/helper"
require "#{File.dirname(__FILE__)}/king_form/overrides"
require "#{File.dirname(__FILE__)}/king_form/builder/form_fields_overrides"
require "#{File.dirname(__FILE__)}/king_form/builder/form_fields"
require "#{File.dirname(__FILE__)}/king_form/builder/base"
require "#{File.dirname(__FILE__)}/king_form/builder/definition_list"
require "#{File.dirname(__FILE__)}/king_form/builder/labeled"
require "#{File.dirname(__FILE__)}/king_form/nested_form_helper"

# You need:
# - haml
# - mutlilang via I18n or gettext ??
# -switch to allow default rails helper

# extend AC with our helper module
ActionController::Base.helper KingForm::Helper

# include the nested_form helper method on the very top of FormBuilder
ActionView::Helpers::FormBuilder.class_eval { include KingForm::NestedFormHelper }