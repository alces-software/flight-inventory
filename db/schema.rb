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

ActiveRecord::Schema.define(version: 2018_07_26_120304) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "chassis", force: :cascade do |t|
    t.string "name", null: false
    t.json "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "genders", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "genders_nodes", id: false, force: :cascade do |t|
    t.bigint "gender_id", null: false
    t.bigint "node_id", null: false
    t.index ["gender_id", "node_id"], name: "index_genders_nodes_on_gender_id_and_node_id"
    t.index ["node_id", "gender_id"], name: "index_genders_nodes_on_node_id_and_gender_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.json "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "network_adapter_ports", force: :cascade do |t|
    t.bigint "network_adapter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "number", null: false
    t.index ["network_adapter_id"], name: "index_network_adapter_ports_on_network_adapter_id"
  end

  create_table "network_adapters", force: :cascade do |t|
    t.string "name", null: false
    t.json "data", null: false
    t.bigint "server_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["server_id"], name: "index_network_adapters_on_server_id"
  end

  create_table "network_connections", force: :cascade do |t|
    t.bigint "network_adapter_port_id", null: false
    t.bigint "network_switch_id", null: false
    t.bigint "network_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "node_id"
    t.string "interface"
    t.index ["network_adapter_port_id"], name: "index_network_connections_on_network_adapter_port_id"
    t.index ["network_id"], name: "index_network_connections_on_network_id"
    t.index ["network_switch_id"], name: "index_network_connections_on_network_switch_id"
    t.index ["node_id"], name: "index_network_connections_on_node_id"
  end

  create_table "network_switches", force: :cascade do |t|
    t.string "name", null: false
    t.json "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "oob_id", null: false
    t.index ["oob_id"], name: "index_network_switches_on_oob_id"
  end

  create_table "networks", force: :cascade do |t|
    t.string "name", null: false
    t.string "cable_colour", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "data", null: false
  end

  create_table "nodes", force: :cascade do |t|
    t.string "name", null: false
    t.json "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "server_id"
    t.bigint "group_id"
    t.index ["group_id"], name: "index_nodes_on_group_id"
    t.index ["server_id"], name: "index_nodes_on_server_id"
  end

  create_table "oobs", force: :cascade do |t|
    t.json "data", null: false
    t.bigint "network_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["network_id"], name: "index_oobs_on_network_id"
  end

  create_table "pdus", force: :cascade do |t|
    t.string "name", null: false
    t.json "data", null: false
    t.bigint "oob_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oob_id"], name: "index_pdus_on_oob_id"
  end

  create_table "psus", force: :cascade do |t|
    t.string "name", null: false
    t.json "data", null: false
    t.bigint "chassis_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chassis_id"], name: "index_psus_on_chassis_id"
  end

  create_table "servers", force: :cascade do |t|
    t.string "name", null: false
    t.json "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "chassis_id"
    t.bigint "oob_id", null: false
    t.index ["chassis_id"], name: "index_servers_on_chassis_id"
    t.index ["oob_id"], name: "index_servers_on_oob_id"
  end

  add_foreign_key "network_adapter_ports", "network_adapters"
  add_foreign_key "network_adapters", "servers"
  add_foreign_key "network_connections", "nodes"
  add_foreign_key "network_switches", "oobs"
  add_foreign_key "nodes", "groups"
  add_foreign_key "nodes", "servers"
  add_foreign_key "pdus", "oobs"
  add_foreign_key "psus", "chassis"
  add_foreign_key "servers", "chassis"
  add_foreign_key "servers", "oobs"
end
