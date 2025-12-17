-- Add brewfather_id to yeast_bank_entries table to track external source
alter table if exists aibrewgenius.yeast_bank_entries 
add column if not exists brewfather_id text;
