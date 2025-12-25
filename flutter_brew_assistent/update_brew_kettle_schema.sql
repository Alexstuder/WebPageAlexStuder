-- Migration to add post_boil_loss_liters to brew_kettles table
ALTER TABLE aibrewgenius.brew_kettles 
ADD COLUMN IF NOT EXISTS post_boil_loss_liters DECIMAL(10, 2);
