-- Create table for storing AI generated recipes
CREATE TABLE IF NOT EXISTS public.ai_generated_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    name TEXT,
    style TEXT,
    recipe_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.ai_generated_recipes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own generated recipes" 
    ON public.ai_generated_recipes 
    FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own generated recipes" 
    ON public.ai_generated_recipes 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own generated recipes" 
    ON public.ai_generated_recipes 
    FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own generated recipes" 
    ON public.ai_generated_recipes 
    FOR DELETE 
    USING (auth.uid() = user_id);
