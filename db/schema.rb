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

ActiveRecord::Schema.define(version: 20200109190556) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "brandings", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "brand_id"
    t.index ["brand_id"], name: "index_brandings_on_brand_id"
    t.index ["product_id"], name: "index_brandings_on_product_id"
  end

  create_table "brands", force: :cascade do |t|
    t.string "title"
    t.text "description"
  end

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

  create_table "daily_facts", force: :cascade do |t|
    t.integer "remote_id"
    t.bigint "product_id"
    t.bigint "category_id"
    t.bigint "brand_id"
    t.integer "original_price"
    t.integer "discount_price"
    t.integer "coupon_price"
    t.integer "sold_count"
    t.integer "rating"
    t.boolean "is_available"
    t.string "sizes", default: [], array: true
    t.date "created_at", null: false
    t.integer "feedback_count"
    t.index ["brand_id"], name: "index_daily_facts_on_brand_id"
    t.index ["category_id"], name: "index_daily_facts_on_category_id"
    t.index ["created_at"], name: "index_daily_facts_on_created_at"
    t.index ["product_id", "created_at"], name: "index_daily_facts_on_product_id_and_created_at"
    t.index ["product_id"], name: "index_daily_facts_on_product_id"
  end

  create_table "daily_report_tasks", force: :cascade do |t|
    t.string "status"
    t.date "start_at"
    t.date "end_at"
    t.datetime "dequeued_at"
    t.string "filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
  end

  create_table "hourly_facts", force: :cascade do |t|
    t.bigint "product_id"
    t.string "sizes", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_hourly_facts_on_created_at"
    t.index ["product_id"], name: "index_hourly_facts_on_product_id"
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
    t.integer "remote_id"
    t.integer "original_price"
    t.integer "discount_price"
    t.integer "coupon_price"
    t.integer "sold_count"
    t.integer "rating"
    t.integer "feedback_count"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["remote_id"], name: "index_products_on_remote_id"
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "propertings", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "property_id", null: false
    t.index ["product_id", "property_id"], name: "index_propertings_on_product_id_and_property_id"
    t.index ["property_id", "product_id"], name: "index_propertings_on_property_id_and_product_id"
  end

  create_table "source_links", force: :cascade do |t|
    t.bigint "wide_sync_task_id"
    t.string "status"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wide_sync_task_id"], name: "index_source_links_on_wide_sync_task_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name"
    t.string "host"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.integer "role"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "wide_sync_tasks", force: :cascade do |t|
    t.bigint "supplier_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "index_wide_sync_tasks_on_supplier_id"
  end

  add_foreign_key "brandings", "brands"
  add_foreign_key "brandings", "products"
  add_foreign_key "colorations", "colors"
  add_foreign_key "colorations", "products"
  add_foreign_key "daily_facts", "brands"
  add_foreign_key "daily_facts", "categories"
  add_foreign_key "daily_facts", "products"
  add_foreign_key "hourly_facts", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "suppliers"
  add_foreign_key "source_links", "wide_sync_tasks"
  add_foreign_key "wide_sync_tasks", "suppliers"
end
