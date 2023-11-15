class CreateImages < ActiveRecord::Migration[7.0]
  def change
    create_table :images do |t|
      t.string :title
      t.text :description, optional: true
      t.string :url

      t.timestamps
    end
  end
end
