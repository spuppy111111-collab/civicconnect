-- ============================================================================
-- CivicConnect Production Supabase Schema
-- Tagline: "Your City. Your Voice. Your Right."
-- ============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 2. ENUMS & TYPES
-- ============================================================================

-- Roles: CITIZEN, ADMIN, OFFICER, FIELD_WORKER, SUPER_ADMIN
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('CITIZEN', 'ADMIN', 'OFFICER', 'FIELD_WORKER', 'SUPER_ADMIN');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Priorities: LOW, MEDIUM, HIGH, EMERGENCY
DO $$ BEGIN
    CREATE TYPE complaint_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'EMERGENCY');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Status: SUBMITTED, UNDER_REVIEW, ASSIGNED, IN_PROGRESS, RESOLVED, REJECTED, CLOSED
DO $$ BEGIN
    CREATE TYPE complaint_status AS ENUM ('SUBMITTED', 'UNDER_REVIEW', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'REJECTED', 'CLOSED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- 3. PROFILES TABLE (Linked to auth.users)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL DEFAULT 'Citizen',
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'CITIZEN' CHECK (role IN ('CITIZEN', 'ADMIN', 'OFFICER', 'FIELD_WORKER', 'SUPER_ADMIN')),
    account_status TEXT NOT NULL DEFAULT 'active' CHECK (account_status IN ('active', 'suspended', 'blocked')),
    avatar_url TEXT,
    points INT DEFAULT 100,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index on role & account_status
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(account_status);

-- ============================================================================
-- 4. DEPARTMENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    sla_hours INT NOT NULL DEFAULT 48,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 5. CATEGORIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL UNIQUE,
    short_name TEXT,
    emoji TEXT,
    description TEXT,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    sub_problems TEXT[] DEFAULT '{}',
    color TEXT,
    badge_bg TEXT,
    badge_border TEXT,
    badge_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_categories_key ON public.categories(key);

-- ============================================================================
-- 6. COMPLAINTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_number TEXT UNIQUE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    category_key TEXT NOT NULL DEFAULT 'other',
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    assigned_officer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'MEDIUM',
    status TEXT NOT NULL DEFAULT 'SUBMITTED',
    address TEXT,
    city TEXT DEFAULT 'Guntur',
    state TEXT DEFAULT 'Andhra Pradesh',
    pincode TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    -- Public Work Transparency & Project Planning Fields
    estimated_start_date TIMESTAMPTZ,
    actual_start_date TIMESTAMPTZ,
    expected_completion_date TIMESTAMPTZ,
    actual_completion_date TIMESTAMPTZ,
    resolution_deadline TIMESTAMPTZ,
    estimated_duration_days INT,
    estimated_budget NUMERIC(12,2),
    approved_budget NUMERIC(12,2),
    amount_spent NUMERIC(12,2) DEFAULT 0,
    work_progress INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ
);

-- Migration safety for existing tables:
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS estimated_start_date TIMESTAMPTZ;
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS actual_start_date TIMESTAMPTZ;
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS expected_completion_date TIMESTAMPTZ;
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS actual_completion_date TIMESTAMPTZ;
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS resolution_deadline TIMESTAMPTZ;
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS estimated_duration_days INT;
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS estimated_budget NUMERIC(12,2);
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS approved_budget NUMERIC(12,2);
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS amount_spent NUMERIC(12,2) DEFAULT 0;
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS work_progress INT DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_complaints_user ON public.complaints(user_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON public.complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_priority ON public.complaints(priority);
CREATE INDEX IF NOT EXISTS idx_complaints_category ON public.complaints(category_key);
CREATE INDEX IF NOT EXISTS idx_complaints_created_at ON public.complaints(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_complaints_number ON public.complaints(complaint_number);
CREATE INDEX IF NOT EXISTS idx_complaints_deadline ON public.complaints(expected_completion_date);

-- ============================================================================
-- 6B. COMPLAINT PROJECT UPDATES TABLE (Transparency History)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.complaint_project_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    update_type TEXT NOT NULL, -- 'TIMELINE_SCHEDULED', 'BUDGET_APPROVED', 'SPENDING_UPDATED', 'PROGRESS_UPDATED', 'EVIDENCE_UPLOADED', 'DEADLINE_UPDATED', 'STATUS_CHANGED'
    previous_value TEXT,
    new_value TEXT,
    description TEXT,
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_project_updates_complaint_id ON public.complaint_project_updates(complaint_id);

-- ============================================================================
-- 6C. COMPLAINT DEADLINE HISTORY TABLE (Deadline Revision Audit)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.complaint_deadline_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    old_deadline TIMESTAMPTZ,
    new_deadline TIMESTAMPTZ NOT NULL,
    changed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_deadline_history_complaint_id ON public.complaint_deadline_history(complaint_id);

-- ============================================================================
-- 6D. COMPLAINT EVIDENCE TABLE (Before, During/Progress, After Work)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.complaint_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    phase TEXT NOT NULL CHECK (phase IN ('before', 'progress', 'after')),
    media_type TEXT NOT NULL DEFAULT 'image' CHECK (media_type IN ('image', 'video')),
    media_url TEXT NOT NULL,
    caption TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_complaint_evidence_complaint_id ON public.complaint_evidence(complaint_id);
CREATE INDEX IF NOT EXISTS idx_complaint_evidence_phase ON public.complaint_evidence(phase);

-- ============================================================================
-- 7. COMPLAINT IMAGES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.complaint_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    file_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_complaint_images_complaint_id ON public.complaint_images(complaint_id);

-- ============================================================================
-- 8. COMPLAINT VIDEOS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.complaint_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    file_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_complaint_videos_complaint_id ON public.complaint_videos(complaint_id);

-- ============================================================================
-- 9. COMPLAINT STATUS HISTORY TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.complaint_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    old_status TEXT,
    new_status TEXT NOT NULL,
    note TEXT,
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_status_history_complaint_id ON public.complaint_status_history(complaint_id);

-- ============================================================================
-- 10. COMPLAINT ASSIGNMENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.complaint_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    officer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    assigned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_assignments_complaint_id ON public.complaint_assignments(complaint_id);
CREATE INDEX IF NOT EXISTS idx_assignments_officer_id ON public.complaint_assignments(officer_id);

-- ============================================================================
-- 11. NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'info',
    complaint_id UUID REFERENCES public.complaints(id) ON DELETE CASCADE,
    read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(read);

-- ============================================================================
-- 12. FEEDBACK TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_helpful BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_feedback_complaint_id ON public.feedback(complaint_id);

-- ============================================================================
-- 13. EMERGENCY REPORTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.emergency_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID REFERENCES public.complaints(id) ON DELETE SET NULL,
    hazard_type TEXT NOT NULL,
    description TEXT NOT NULL,
    location TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    reporter_name TEXT,
    reporter_phone TEXT,
    severity TEXT NOT NULL DEFAULT 'HIGH',
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_emergency_status ON public.emergency_reports(status);

-- ============================================================================
-- 14. AI ANALYSIS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.ai_analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES public.complaints(id) ON DELETE CASCADE,
    image_url TEXT,
    detected_category TEXT,
    confidence NUMERIC,
    severity_predicted TEXT,
    raw_result JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_analysis_complaint_id ON public.ai_analysis(complaint_id);

-- ============================================================================
-- 15. AUTOMATED FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function 1: Automatically create a Profile when a User signs up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_name TEXT;
    user_role_val TEXT;
    user_phone_val TEXT;
BEGIN
    default_name := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1));
    user_role_val := COALESCE(NEW.raw_user_meta_data->>'role', 'CITIZEN');
    user_phone_val := NEW.raw_user_meta_data->>'phone';

    INSERT INTO public.profiles (id, full_name, phone, role, account_status, avatar_url, points)
    VALUES (
        NEW.id,
        default_name,
        user_phone_val,
        user_role_val,
        'active',
        NEW.raw_user_meta_data->>'avatar_url',
        100
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        role = COALESCE(EXCLUDED.role, public.profiles.role),
        phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
        updated_at = now();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- Function 2: Generate complaint number if not provided
CREATE OR REPLACE FUNCTION public.generate_complaint_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.complaint_number IS NULL OR NEW.complaint_number = '' THEN
        NEW.complaint_number := 'CC-' || to_char(now(), 'YYYY') || '-' || lpad(floor(random() * 900000 + 100000)::text, 6, '0');
    END IF;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_complaint_number ON public.complaints;
CREATE TRIGGER trg_complaint_number
    BEFORE INSERT ON public.complaints
    FOR EACH ROW EXECUTE FUNCTION public.generate_complaint_number();


-- Function 3: Log Status History and Send Notification to Citizen on Status Change
CREATE OR REPLACE FUNCTION public.handle_complaint_status_change()
RETURNS TRIGGER AS $$
DECLARE
    notif_title TEXT;
    notif_msg TEXT;
BEGIN
    IF (OLD.status IS DISTINCT FROM NEW.status) THEN
        -- 1. Insert history record
        INSERT INTO public.complaint_status_history (
            complaint_id,
            old_status,
            new_status,
            note,
            created_at
        ) VALUES (
            NEW.id,
            OLD.status,
            NEW.status,
            'Status updated from ' || OLD.status || ' to ' || NEW.status,
            now()
        );

        -- 2. If status is RESOLVED, set resolved_at
        IF UPPER(NEW.status) = 'RESOLVED' OR NEW.status = 'resolved' THEN
            NEW.resolved_at := now();
        END IF;

        -- 3. If user_id exists, send a real-time Notification
        IF NEW.user_id IS NOT NULL THEN
            notif_title := 'Status Updated: ' || NEW.title;
            notif_msg := 'Your complaint #' || NEW.complaint_number || ' status is now ' || REPLACE(NEW.status, '_', ' ') || '.';

            INSERT INTO public.notifications (
                user_id,
                title,
                message,
                type,
                complaint_id,
                read,
                created_at
            ) VALUES (
                NEW.user_id,
                notif_title,
                notif_msg,
                LOWER(NEW.status),
                NEW.id,
                FALSE,
                now()
            );
        END IF;

        NEW.updated_at := now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_complaint_status_change ON public.complaints;
CREATE TRIGGER trg_complaint_status_change
    BEFORE UPDATE ON public.complaints
    FOR EACH ROW EXECUTE FUNCTION public.handle_complaint_status_change();


-- ============================================================================
-- 16. SEED DATA (Departments & Categories)
-- ============================================================================

-- Insert Departments
INSERT INTO public.departments (name, description, icon, contact_email, sla_hours)
VALUES
    ('Roads Department', 'Potholes, damaged tarmac, dividers, signboards and traffic signals', 'Road', 'roads@civicconnect.gov', 48),
    ('Water Department', 'Pipeline leakage, water supply shortages, contamination and valve repairs', 'Droplets', 'water@civicconnect.gov', 24),
    ('Electricity Department', 'Street lights, transformer issues, fallen electrical wires and power outages', 'Zap', 'electricity@civicconnect.gov', 24),
    ('Sanitation Department', 'Garbage collection, overflowing waste bins, dead animals and road sweeping', 'Trash2', 'sanitation@civicconnect.gov', 24),
    ('Drainage Department', 'Blocked gutters, open manholes, monsoon flooding and stormwater overflow', 'Waves', 'drainage@civicconnect.gov', 36),
    ('Public Health Department', 'Mosquito fogging, open sewage overflow, public toilet hygiene and sanitation', 'ShieldAlert', 'health@civicconnect.gov', 48),
    ('Municipal Administration', 'Illegal construction, encroachments, park maintenance, and general civic issues', 'Building2', 'admin@civicconnect.gov', 72)
ON CONFLICT (name) DO NOTHING;

-- Insert Categories matching CivicConnect UI
INSERT INTO public.categories (key, name, short_name, emoji, description, sub_problems, color, badge_bg, badge_border, badge_text)
VALUES
    ('roads', 'Road Damage & Potholes', 'Road Damage', '🛣️', 'Potholes, broken roads, missing dividers, and road repairs.',
     ARRAY['Potholes on road', 'Broken or cracked road surface', 'Missing or broken road divider', 'Faded zebra crossing / markings', 'Damaged speed breaker', 'Road cave-in / sinkhole'],
     'blue', 'bg-blue-500/10', 'border-blue-500/30', 'text-blue-300'),

    ('waste', 'Garbage & Waste Disposal', 'Garbage & Waste', '🗑️', 'Overflowing dumpsters, uncollected garbage, and illegal dumping.',
     ARRAY['Garbage not collected', 'Overflowing public dustbin', 'Illegal dumping in vacant lot', 'Dead animal on street', 'Plastic waste accumulation', 'Construction debris on pavement'],
     'amber', 'bg-amber-500/10', 'border-amber-500/30', 'text-amber-300'),

    ('water', 'Water Supply & Pipelines', 'Water Supply', '💧', 'Pipe bursts, contaminated water, low pressure, and leakages.',
     ARRAY['Water pipe burst / major leak', 'No water supply in area', 'Dirty / contaminated drinking water', 'Low water pressure', 'Leaking public tap / valve', 'Water tanker delivery delayed'],
     'sky', 'bg-sky-500/10', 'border-sky-500/30', 'text-sky-300'),

    ('electricity', 'Street Lights & Electricity', 'Street Lights', '💡', 'Non-functioning street lights, exposed wiring, and power issues.',
     ARRAY['Street light not working / flickering', 'Entire street dark at night', 'Broken street light pole', 'Exposed or hanging live electrical wires', 'Transformer sparking / failure', 'Street lights on during daytime'],
     'yellow', 'bg-yellow-500/10', 'border-yellow-500/30', 'text-yellow-300'),

    ('drainage', 'Drainage & Sewage Issues', 'Drainage / Sewage', '🌊', 'Blocked drains, open manholes, overflowing sewage, and waterlogging.',
     ARRAY['Blocked / overflowing open drain', 'Open or broken manhole cover', 'Waterlogging after rainfall', 'Foul smell from drainage line', 'Sewage backflow in residential area', 'Drainage culvert damaged'],
     'teal', 'bg-teal-500/10', 'border-teal-500/30', 'text-teal-300'),

    ('health', 'Public Health & Sanitation', 'Public Health', '🏥', 'Mosquito breeding, stray animals, dirty public toilets, and fogging.',
     ARRAY['Mosquito breeding / fogging needed', 'Stray dog menace / unvaccinated animals', 'Dirty / unusable public toilet', 'Unsanitary open defecation spot', 'Stagnant water near schools / parks', 'Food hygiene issue at street vendor'],
     'emerald', 'bg-emerald-500/10', 'border-emerald-500/30', 'text-emerald-300'),

    ('construction', 'Illegal Construction & Encroachment', 'Encroachment', '🏗️', 'Footpath encroachments, unauthorized building, and noise.',
     ARRAY['Footpath / road encroachment by shop', 'Illegal construction without permission', 'Unauthorized tree cutting', 'Blocked public walkway', 'Loud construction at night', 'Hazardous building structure'],
     'purple', 'bg-purple-500/10', 'border-purple-500/30', 'text-purple-300'),

    ('parks', 'Parks, Trees & Greenery', 'Parks & Trees', '🌳', 'Dangerous tree branches, neglected parks, and broken playground gear.',
     ARRAY['Dangerous hanging tree branch', 'Fallen tree blocking road', 'Neglected public park / overgrown grass', 'Broken children swing / play equipment', 'Park lighting not working', 'Garbage dumped in park'],
     'green', 'bg-green-500/10', 'border-green-500/30', 'text-green-300'),

    ('traffic', 'Traffic, Parking & Transport', 'Traffic & Parking', '🚦', 'Broken traffic signals, illegal parking, and missing signs.',
     ARRAY['Traffic light / signal not working', 'Illegal parking blocking street', 'Missing stop sign / direction board', 'Bus stop shelter damaged', 'Speeding vehicle menace / need speed bump', 'Broken pedestrian railing'],
     'orange', 'bg-orange-500/10', 'border-orange-500/30', 'text-orange-300'),

    ('air', 'Air Pollution & Noise Nuisance', 'Pollution & Noise', '🌫️', 'Open burning of garbage, industrial emissions, and loud speakers.',
     ARRAY['Open burning of garbage / leaves', 'Heavy industrial smoke / emission', 'Loudspeaker noise beyond permissible hours', 'Excessive dust from unpaved road', 'Generator smoke / continuous noise', 'Chemical odor in neighborhood'],
     'slate', 'bg-slate-500/10', 'border-slate-500/30', 'text-slate-300'),

    ('other', 'Other Civic Complaints', 'Other Civic Issues', '📋', 'Any other municipal issue not listed above.',
     ARRAY['Property tax / municipal billing issue', 'Birth / death certificate delay', 'Vandalism of public property', 'Street name board missing', 'Other civic grievance'],
     'indigo', 'bg-indigo-500/10', 'border-indigo-500/30', 'text-indigo-300')
ON CONFLICT (key) DO NOTHING;

-- Link categories with department_ids
UPDATE public.categories SET department_id = (SELECT id FROM public.departments WHERE name = 'Roads Department' LIMIT 1) WHERE key IN ('roads', 'traffic');
UPDATE public.categories SET department_id = (SELECT id FROM public.departments WHERE name = 'Water Department' LIMIT 1) WHERE key = 'water';
UPDATE public.categories SET department_id = (SELECT id FROM public.departments WHERE name = 'Electricity Department' LIMIT 1) WHERE key = 'electricity';
UPDATE public.categories SET department_id = (SELECT id FROM public.departments WHERE name = 'Sanitation Department' LIMIT 1) WHERE key = 'waste';
UPDATE public.categories SET department_id = (SELECT id FROM public.departments WHERE name = 'Drainage Department' LIMIT 1) WHERE key = 'drainage';
UPDATE public.categories SET department_id = (SELECT id FROM public.departments WHERE name = 'Public Health Department' LIMIT 1) WHERE key IN ('health', 'air');
UPDATE public.categories SET department_id = (SELECT id FROM public.departments WHERE name = 'Municipal Administration' LIMIT 1) WHERE key IN ('construction', 'parks', 'other');


-- ============================================================================
-- 17. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_analysis ENABLE ROW LEVEL SECURITY;

-- Helper function to check if current user is admin/super_admin/officer
CREATE OR REPLACE FUNCTION public.is_admin_or_officer()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role IN ('ADMIN', 'OFFICER', 'SUPER_ADMIN')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --- PROFILES POLICIES ---
DROP POLICY IF EXISTS "Public profiles read" ON public.profiles;
CREATE POLICY "Public profiles read" ON public.profiles FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
CREATE POLICY "Admins can manage all profiles" ON public.profiles FOR ALL
    USING (public.is_admin_or_officer());

-- --- DEPARTMENTS & CATEGORIES POLICIES ---
DROP POLICY IF EXISTS "Anyone can view departments" ON public.departments;
CREATE POLICY "Anyone can view departments" ON public.departments FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admins can manage departments" ON public.departments;
CREATE POLICY "Admins can manage departments" ON public.departments FOR ALL
    USING (public.is_admin_or_officer());

DROP POLICY IF EXISTS "Anyone can view categories" ON public.categories;
CREATE POLICY "Anyone can view categories" ON public.categories FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admins can manage categories" ON public.categories;
CREATE POLICY "Admins can manage categories" ON public.categories FOR ALL
    USING (public.is_admin_or_officer());

-- --- COMPLAINTS POLICIES ---
-- Read: Public can view verified complaints, authenticated users see own complaints, admins/officers see all
DROP POLICY IF EXISTS "Citizens and public view complaints" ON public.complaints;
CREATE POLICY "Citizens and public view complaints" ON public.complaints FOR SELECT
    USING (
        auth.uid() = user_id OR
        public.is_admin_or_officer() OR
        auth.uid() IS NULL -- allows demo browsing
    );

-- Insert: Any authenticated user can file complaints (or anonymous for demo)
DROP POLICY IF EXISTS "Authenticated users create complaints" ON public.complaints;
CREATE POLICY "Authenticated users create complaints" ON public.complaints FOR INSERT
    WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL OR public.is_admin_or_officer());

-- Update: Owner can edit before review, admins/officers can update status & details
DROP POLICY IF EXISTS "Update complaints" ON public.complaints;
CREATE POLICY "Update complaints" ON public.complaints FOR UPDATE
    USING (auth.uid() = user_id OR public.is_admin_or_officer());

-- Delete: Admins or owner
DROP POLICY IF EXISTS "Delete complaints" ON public.complaints;
CREATE POLICY "Delete complaints" ON public.complaints FOR DELETE
    USING (auth.uid() = user_id OR public.is_admin_or_officer());

-- --- COMPLAINT IMAGES & VIDEOS POLICIES ---
DROP POLICY IF EXISTS "Images viewable by all" ON public.complaint_images;
CREATE POLICY "Images viewable by all" ON public.complaint_images FOR SELECT USING (true);

DROP POLICY IF EXISTS "Images insertable by creator or admin" ON public.complaint_images;
CREATE POLICY "Images insertable by creator or admin" ON public.complaint_images FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Videos viewable by all" ON public.complaint_videos;
CREATE POLICY "Videos viewable by all" ON public.complaint_videos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Videos insertable by creator or admin" ON public.complaint_videos;
CREATE POLICY "Videos insertable by creator or admin" ON public.complaint_videos FOR INSERT WITH CHECK (true);

-- --- NOTIFICATIONS POLICIES ---
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT
    USING (auth.uid() = user_id OR public.is_admin_or_officer() OR auth.uid() IS NULL);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id OR public.is_admin_or_officer() OR auth.uid() IS NULL);

DROP POLICY IF EXISTS "Notifications insertable" ON public.notifications;
CREATE POLICY "Notifications insertable" ON public.notifications FOR INSERT
    WITH CHECK (true);

-- --- STATUS HISTORY & ASSIGNMENTS ---
DROP POLICY IF EXISTS "Status history viewable by all" ON public.complaint_status_history;
CREATE POLICY "Status history viewable by all" ON public.complaint_status_history FOR SELECT USING (true);

DROP POLICY IF EXISTS "Status history insertable by admins/officers" ON public.complaint_status_history;
CREATE POLICY "Status history insertable by admins/officers" ON public.complaint_status_history FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Assignments viewable by all" ON public.complaint_assignments;
CREATE POLICY "Assignments viewable by all" ON public.complaint_assignments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Assignments insertable by admins" ON public.complaint_assignments;
CREATE POLICY "Assignments insertable by admins" ON public.complaint_assignments FOR ALL USING (public.is_admin_or_officer());

-- --- FEEDBACK POLICIES ---
DROP POLICY IF EXISTS "Feedback readable by all" ON public.feedback;
CREATE POLICY "Feedback readable by all" ON public.feedback FOR SELECT USING (true);

DROP POLICY IF EXISTS "Feedback insertable by users" ON public.feedback;
CREATE POLICY "Feedback insertable by users" ON public.feedback FOR INSERT WITH CHECK (true);

-- --- EMERGENCY REPORTS POLICIES ---
DROP POLICY IF EXISTS "Emergency reports readable by all" ON public.emergency_reports;
CREATE POLICY "Emergency reports readable by all" ON public.emergency_reports FOR SELECT USING (true);

DROP POLICY IF EXISTS "Emergency reports insertable" ON public.emergency_reports;
CREATE POLICY "Emergency reports insertable" ON public.emergency_reports FOR INSERT WITH CHECK (true);

-- --- AI ANALYSIS POLICIES ---
DROP POLICY IF EXISTS "AI analysis readable by all" ON public.ai_analysis;
CREATE POLICY "AI analysis readable by all" ON public.ai_analysis FOR SELECT USING (true);

DROP POLICY IF EXISTS "AI analysis insertable" ON public.ai_analysis;
CREATE POLICY "AI analysis insertable" ON public.ai_analysis FOR INSERT WITH CHECK (true);

-- --- PROJECT TRANSPARENCY & EVIDENCE POLICIES ---
DROP POLICY IF EXISTS "Project updates viewable by all" ON public.complaint_project_updates;
CREATE POLICY "Project updates viewable by all" ON public.complaint_project_updates FOR SELECT USING (true);

DROP POLICY IF EXISTS "Project updates insertable" ON public.complaint_project_updates;
CREATE POLICY "Project updates insertable" ON public.complaint_project_updates FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Deadline history viewable by all" ON public.complaint_deadline_history;
CREATE POLICY "Deadline history viewable by all" ON public.complaint_deadline_history FOR SELECT USING (true);

DROP POLICY IF EXISTS "Deadline history insertable" ON public.complaint_deadline_history;
CREATE POLICY "Deadline history insertable" ON public.complaint_deadline_history FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Evidence viewable by all" ON public.complaint_evidence;
CREATE POLICY "Evidence viewable by all" ON public.complaint_evidence FOR SELECT USING (true);

DROP POLICY IF EXISTS "Evidence insertable" ON public.complaint_evidence;
CREATE POLICY "Evidence insertable" ON public.complaint_evidence FOR INSERT WITH CHECK (true);

-- ============================================================================
-- 18. SUPABASE REALTIME CONFIGURATION
-- ============================================================================
-- Enable Realtime on complaints, notifications, and status history
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.complaints;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.complaint_status_history;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.complaint_project_updates;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.complaint_deadline_history;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.complaint_evidence;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- 19. SUPABASE STORAGE BUCKET INSTRUCTIONS (Run in Storage SQL / UI)
-- ============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('complaint-images', 'complaint-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('complaint-videos', 'complaint-videos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies for complaint-images
DROP POLICY IF EXISTS "Public complaint images access" ON storage.objects;
CREATE POLICY "Public complaint images access" ON storage.objects FOR SELECT
    USING (bucket_id IN ('complaint-images', 'complaint-videos'));

DROP POLICY IF EXISTS "Authenticated users upload complaint images" ON storage.objects;
CREATE POLICY "Authenticated users upload complaint images" ON storage.objects FOR INSERT
    WITH CHECK (bucket_id IN ('complaint-images', 'complaint-videos'));
