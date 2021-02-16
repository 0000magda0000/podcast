class CreateEpisodes < ActiveRecord::Migration[6.0]
  def change
    create_table :episodes do |t|
      t.string :title
      t.string :subtitle
      t.string :description
      t.string :cover_image
      t.integer :duration
      t.timestamp :published_at
      t.string :permalink
      t.text :shownotes
      t.timestamps
    end
  end
end
