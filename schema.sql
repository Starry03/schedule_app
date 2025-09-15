-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.classes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  grade integer NOT NULL,
  section text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT classes_pkey PRIMARY KEY (id)
);
CREATE TABLE public.schedule_slots (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  schedule_id uuid NOT NULL,
  teacher_id uuid NOT NULL,
  subject_id uuid NOT NULL,
  day_of_week integer NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 5),
  hour_slot integer NOT NULL CHECK (hour_slot >= 1 AND hour_slot <= 6),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  class_id uuid NOT NULL,
  CONSTRAINT schedule_slots_pkey PRIMARY KEY (id),
  CONSTRAINT schedule_slots_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.classes(id),
  CONSTRAINT schedule_slots_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id),
  CONSTRAINT schedule_slots_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id),
  CONSTRAINT schedule_slots_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id)
);
CREATE TABLE public.schedules (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  generation_seed integer NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT schedules_pkey PRIMARY KEY (id)
);
CREATE TABLE public.subjects (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  weekly_hours integer NOT NULL DEFAULT 1,
  prefer_consecutive boolean DEFAULT false,
  max_consecutive_hours integer DEFAULT 2,
  max_daily_hours integer DEFAULT 2,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT subjects_pkey PRIMARY KEY (id)
);
CREATE TABLE public.teacher_constraints (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid NOT NULL,
  day_of_week integer NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 5),
  hour_slot integer NOT NULL CHECK (hour_slot >= 1 AND hour_slot <= 6),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT teacher_constraints_pkey PRIMARY KEY (id),
  CONSTRAINT teacher_constraints_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id)
);
CREATE TABLE public.teacher_subjects (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid NOT NULL,
  subject_id uuid NOT NULL,
  class_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT teacher_subjects_pkey PRIMARY KEY (id),
  CONSTRAINT teacher_subjects_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.classes(id),
  CONSTRAINT teacher_subjects_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id),
  CONSTRAINT teacher_subjects_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id)
);
CREATE TABLE public.teachers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text UNIQUE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  extra_hours integer NOT NULL DEFAULT 0 CHECK (extra_hours >= 0),
  CONSTRAINT teachers_pkey PRIMARY KEY (id)
);