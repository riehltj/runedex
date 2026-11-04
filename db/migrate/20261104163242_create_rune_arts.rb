class CreateRuneArts < ActiveRecord::Migration[8.1]
  def change
    create_table :rune_arts do |t|
      t.string :domain, null: false
      t.string :set_name, null: false
      t.string :variant, null: false, default: "Alternate Art"
      t.string :title
      t.string :artist
      t.string :source
      t.string :image_url
      t.string :collector_number
      t.date :released_on
      t.text :notes

      t.timestamps
    end
    add_index :rune_arts, :domain
    add_index :rune_arts, :set_name
  end
end
