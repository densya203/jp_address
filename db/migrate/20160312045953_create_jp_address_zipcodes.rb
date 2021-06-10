class CreateJpAddressZipcodes < ActiveRecord::Migration[5.0]
  def change
    create_table :jp_address_zipcodes do |t|
      t.string :zip       , null: false, index: true
      t.string :prefecture, null: false
      t.string :city      , null: false
      t.string :town
    end
  end
end
