# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180110191958) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "title"
    t.integer "parent_id"
    t.integer "remote_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "colorations", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "color_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["color_id"], name: "index_colorations_on_color_id"
    t.index ["product_id"], name: "index_colorations_on_product_id"
  end

  create_table "colors", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.string "title"
    t.boolean "is_available"
    t.integer "price"
    t.integer "compare_price"
    t.bigint "category_id"
    t.bigint "supplier_id"
    t.string "url"
    t.text "description"
    t.string "slug"
    t.string "collection"
    t.string "color"
    t.string "sizes", default: [], array: true
    t.string "images", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "remote_key"
    t.integer "length"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name"
    t.string "host"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "colorations", "colors"
  add_foreign_key "colorations", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "suppliers"
end
