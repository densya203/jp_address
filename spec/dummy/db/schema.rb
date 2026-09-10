# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This is the schema of the dummy application used by the specs. It mirrors
# db/migrate/ of the engine and is loaded before the suite runs.

ActiveRecord::Schema[7.1].define(version: 2016_03_12_045953) do
  create_table "jp_address_zipcodes", force: :cascade do |t|
    t.string "zip", null: false
    t.string "prefecture", null: false
    t.string "city", null: false
    t.string "town"
    t.index ["zip"], name: "index_jp_address_zipcodes_on_zip"
  end
end
