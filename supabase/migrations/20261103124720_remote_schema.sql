SET local check_function_bodies = off;

CREATE TABLE "public"."attendance_corrections" (
  "id"            uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "attendance_id" uuid                     NOT NULL,
  "employee_id"   uuid                     NOT NULL,
  "field"         text                     NOT NULL,
  "old_value"     text,
  "new_value"     text                     NOT NULL,
  "reason"        text                     NOT NULL,
  "status"        text                     NOT NULL DEFAULT 'Pending'::text,
  "reviewed_by"   uuid,
  "reviewed_at"   timestamp with time zone,
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "attendance_corrections_field_check" CHECK ((field = ANY (ARRAY['clock_in'::text, 'clock_out'::text, 'break_minutes'::text]))),
  CONSTRAINT "attendance_corrections_pkey" PRIMARY KEY (id),
  CONSTRAINT "attendance_corrections_status_check" CHECK ((status = ANY (ARRAY['Pending'::text, 'Approved'::text, 'Rejected'::text])))
);

ALTER TABLE "public"."attendance_corrections"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."attendance" (
  "id"             uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "employee_id"    uuid                     NOT NULL,
  "clock_in"       timestamp with time zone NOT NULL DEFAULT now(),
  "clock_out"      timestamp with time zone,
  "break_minutes"  integer                  NOT NULL DEFAULT 0,
  "total_hours"    numeric(5,2)             GENERATED ALWAYS AS (
CASE
    WHEN (clock_out IS NOT NULL) THEN round(((EXTRACT(epoch FROM (clock_out - clock_in)) / 3600.0) - ((break_minutes)::numeric / 60.0)), 2)
    ELSE NULL::numeric
END) STORED,
  "overtime_hours" numeric(4,2)             NOT NULL DEFAULT 0,
  "status"         text                     NOT NULL DEFAULT 'Open'::text,
  "created_at"     timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "attendance_break_minutes_check" CHECK (((break_minutes >= 0) AND (break_minutes <= 240))),
  CONSTRAINT "attendance_check" CHECK (((clock_out IS NULL) OR (clock_out > clock_in))),
  CONSTRAINT "attendance_pkey" PRIMARY KEY (id),
  CONSTRAINT "attendance_status_check" CHECK ((status = ANY (ARRAY['Open'::text, 'Completed'::text, 'Corrected'::text])))
);

ALTER TABLE "public"."attendance"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."audit_log" (
  "id"         uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "actor_id"   uuid,
  "entity"     text                     NOT NULL,
  "entity_id"  uuid,
  "action"     text                     NOT NULL,
  "details"    jsonb,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "audit_log_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."audit_log"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."departments" (
  "id"         uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "name"       text                     NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "departments_name_key" UNIQUE (name),
  CONSTRAINT "departments_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."departments"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."employees" (
  "id"                  uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "user_id"             uuid                     NOT NULL,
  "employee_code"       text                     NOT NULL,
  "full_name"           text                     NOT NULL,
  "email"               text                     NOT NULL,
  "department_id"       uuid,
  "role"                text                     NOT NULL DEFAULT 'employee'::text,
  "is_active"           boolean                  NOT NULL DEFAULT true,
  "created_at"          timestamp with time zone NOT NULL DEFAULT now(),
  "hourly_rate"         numeric(8,2),
  "tax_number"          text,
  "bank_account_masked" text,
  "job_title"           text,
  CONSTRAINT "employees_employee_code_key" UNIQUE (employee_code),
  CONSTRAINT "employees_pkey" PRIMARY KEY (id),
  CONSTRAINT "employees_role_check" CHECK ((role = ANY (ARRAY['employee'::text, 'supervisor'::text, 'admin'::text]))),
  CONSTRAINT "employees_user_id_key" UNIQUE (user_id)
);

ALTER TABLE "public"."employees"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."overtime" (
  "id"            uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "employee_id"   uuid                     NOT NULL,
  "attendance_id" uuid                     NOT NULL,
  "work_date"     date                     NOT NULL,
  "hours"         numeric(4,2)             NOT NULL,
  "reason"        text                     NOT NULL,
  "status"        text                     NOT NULL DEFAULT 'Pending'::text,
  "reviewed_by"   uuid,
  "reviewed_at"   timestamp with time zone,
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "overtime_attendance_id_key" UNIQUE (attendance_id),
  CONSTRAINT "overtime_hours_check" CHECK (((hours > (0)::numeric) AND (hours <= (12)::numeric))),
  CONSTRAINT "overtime_pkey" PRIMARY KEY (id),
  CONSTRAINT "overtime_status_check" CHECK ((status = ANY (ARRAY['Pending'::text, 'Approved'::text, 'Rejected'::text])))
);

ALTER TABLE "public"."overtime"
  ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.admin_create_employee (
  p_code          text,
  p_full_name     text,
  p_email         text,
  p_role          text,
  p_department_id uuid
)
  RETURNS public.employees
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_user uuid; v_rec public.employees%rowtype;
  v_role text := coalesce(public.current_employee_role(), '');
begin
  if v_role <> 'admin' then raise exception 'Only administrators can manage employees.'; end if;
  if p_role not in ('employee', 'supervisor', 'admin') then raise exception 'Invalid role.'; end if;
  select id into v_user from auth.users where lower(email) = lower(trim(p_email));
  if v_user is null then
    raise exception 'No auth account found for %. Create it first in Supabase Dashboard > Authentication > Users (tick Auto confirm), then retry.', p_email;
  end if;
  insert into public.employees (user_id, employee_code, full_name, email, role, department_id)
  values (v_user, upper(trim(p_code)), trim(p_full_name), lower(trim(p_email)), p_role, p_department_id)
  on conflict (employee_code) do update
    set full_name = excluded.full_name, email = excluded.email, role = excluded.role,
        department_id = excluded.department_id
  returning * into v_rec;
  return v_rec;
end $function$;

CREATE OR REPLACE FUNCTION public.admin_create_employee (
  p_code          text,
  p_full_name     text,
  p_email         text,
  p_role          text,
  p_department_id uuid,
  p_password      text DEFAULT NULL::text
)
  RETURNS public.employees
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'extensions'
  AS $function$
declare
  v_user   uuid;
  v_rec    public.employees%rowtype;
  v_role   text := coalesce(public.current_employee_role(), '');
begin
  if v_role <> 'admin' then raise exception 'Only administrators can manage employees.'; end if;
  if p_role not in ('employee', 'supervisor', 'admin') then raise exception 'Invalid role.'; end if;

  select id into v_user from auth.users where lower(email) = lower(trim(p_email));
  if v_user is null then
    if p_password is null or length(p_password) < 6 then
      raise exception 'A password of at least 6 characters is required for the new account.';
    end if;
    v_user := gen_random_uuid();
    insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at, confirmation_token, email_change,
        email_change_token_new, recovery_token)
    values (
        '00000000-0000-0000-0000-000000000000', v_user, 'authenticated', 'authenticated',
        lower(trim(p_email)), extensions.crypt(p_password, extensions.gen_salt('bf')),
        now(), '{"provider":"email","providers":["email"]}',
        jsonb_build_object('full_name', trim(p_full_name)),
        now(), now(), '', '', '', '');
    insert into auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (gen_random_uuid(), v_user::text, v_user,
            jsonb_build_object('sub', v_user::text, 'email', lower(trim(p_email))),
            'email', null, now(), now());
  end if;

  insert into public.employees (user_id, employee_code, full_name, email, role, department_id)
  values (v_user, upper(trim(p_code)), trim(p_full_name), lower(trim(p_email)), p_role, p_department_id)
  on conflict (employee_code) do update
    set user_id = excluded.user_id, full_name = excluded.full_name, email = excluded.email,
        role = excluded.role, department_id = excluded.department_id
  returning * into v_rec;
  return v_rec;
end $function$;

CREATE OR REPLACE FUNCTION public.admin_update_employee (
  p_id            uuid,
  p_code          text,
  p_full_name     text,
  p_email         text,
  p_role          text,
  p_department_id uuid,
  p_is_active     boolean
)
  RETURNS public.employees
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_rec  public.employees%rowtype;
  v_role text := coalesce(public.current_employee_role(), '');
begin
  if v_role <> 'admin' then raise exception 'Only administrators can manage employees.'; end if;
  update public.employees
     set employee_code = coalesce(nullif(trim(p_code), ''),      employee_code),
         full_name     = coalesce(nullif(trim(p_full_name), ''), full_name),
         email         = coalesce(nullif(trim(p_email), ''),     email),
         role          = case when p_role in ('employee','supervisor','admin')
                              then p_role else role end,
         department_id = coalesce(p_department_id, department_id),
         is_active     = coalesce(p_is_active, is_active)
   where id = p_id
   returning * into v_rec;
  if v_rec.id is null then raise exception 'Employee not found.'; end if;
  return v_rec;
end $function$;

CREATE OR REPLACE FUNCTION public.apply_decision()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
begin
  if new.status = 'Approved' then
    if tg_table_name = 'overtime' then
      update attendance set overtime_hours = new.hours where id = new.attendance_id;
    elsif new.field = 'clock_in' then
      update attendance set clock_in = new.new_value::timestamptz, status = 'Corrected' where id = new.attendance_id;
    elsif new.field = 'clock_out' then
      update attendance set clock_out = new.new_value::timestamptz, status = 'Corrected' where id = new.attendance_id;
    else
      update attendance set break_minutes = new.new_value::integer, status = 'Corrected' where id = new.attendance_id;
    end if;
  end if;
  return null;
end $function$;

CREATE OR REPLACE FUNCTION public.clock_in()
  RETURNS public.attendance
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare emp employees; rec attendance;
begin
  select * into emp from employees where user_id = auth.uid();
  if emp.id is null then raise exception 'No employee profile for this account.'; end if;
  if not emp.is_active then raise exception 'This account is deactivated.'; end if;
  if exists (select 1 from attendance where employee_id = emp.id and clock_out is null) then
    raise exception 'You are already clocked in.';
  end if;
  insert into attendance (employee_id) values (emp.id) returning * into rec;
  return rec;
end $function$;

REVOKE ALL ON FUNCTION "public"."clock_in"() FROM PUBLIC, "anon";

CREATE OR REPLACE FUNCTION public.clock_out()
  RETURNS public.attendance
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare rec attendance;
begin
  update attendance set clock_out = now(), status = 'Completed'
  where employee_id = current_employee_id() and clock_out is null
  returning * into rec;
  if rec.id is null then raise exception 'You are not clocked in.'; end if;
  return rec;
end $function$;

REVOKE ALL ON FUNCTION "public"."clock_out"() FROM PUBLIC, "anon";

CREATE OR REPLACE FUNCTION public.current_employee_id()
  RETURNS uuid
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
  select id from employees where user_id = auth.uid()
$function$;

CREATE OR REPLACE FUNCTION public.current_employee_role()
  RETURNS text
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
  select role from employees where user_id = auth.uid()
$function$;

CREATE OR REPLACE FUNCTION public.guard_review()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
begin
  if old.status <> 'Pending' then raise exception 'This request was already reviewed.'; end if;
  if new.status not in ('Approved', 'Rejected') then raise exception 'Invalid decision.'; end if;
  if old.employee_id = current_employee_id() then raise exception 'You cannot review your own request.'; end if;
  new.reviewed_by := current_employee_id();
  new.reviewed_at := now();
  if tg_table_name = 'overtime' then
    if (new.employee_id, new.attendance_id, new.hours, new.reason, new.work_date)
       is distinct from (old.employee_id, old.attendance_id, old.hours, old.reason, old.work_date) then
      raise exception 'Only the decision can be changed.';
    end if;
  else
    if (new.employee_id, new.attendance_id, new.field, new.new_value, new.reason)
       is distinct from (old.employee_id, old.attendance_id, old.field, old.new_value, old.reason) then
      raise exception 'Only the decision can be changed.';
    end if;
  end if;
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.login_lookup (
  p_email text
)
  RETURNS TABLE (
    id            uuid,
    full_name     text,
    role          text,
    department_id uuid,
    is_active     boolean,
    employee_code text
  )
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
  select id, full_name, role, department_id, is_active, employee_code
    from public.employees
   where lower(email) = lower(trim(p_email));
$function$;

CREATE OR REPLACE FUNCTION public.record_break (
  p_minutes integer
)
  RETURNS public.attendance
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare rec attendance;
begin
  if p_minutes is null or p_minutes < 1 or p_minutes > 120 then
    raise exception 'Break must be between 1 and 120 minutes.';
  end if;
  update attendance set break_minutes = break_minutes + p_minutes
  where employee_id = current_employee_id() and clock_out is null
  returning * into rec;
  if rec.id is null then raise exception 'Clock in before recording a break.'; end if;
  return rec;
end $function$;

REVOKE ALL ON FUNCTION "public"."record_break"(integer) FROM PUBLIC, "anon";

CREATE OR REPLACE FUNCTION public.request_correction (
  p_attendance_id uuid,
  p_field         text,
  p_new_value     text,
  p_reason        text
)
  RETURNS public.attendance_corrections
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare emp uuid := current_employee_id(); att attendance; rec attendance_corrections; old_v text;
begin
  if p_field not in ('clock_in', 'clock_out', 'break_minutes') then raise exception 'Choose what to correct.'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'Enter a reason.'; end if;
  select * into att from attendance where id = p_attendance_id and employee_id = emp;
  if att.id is null then raise exception 'Attendance record not found.'; end if;
  begin
    if p_field = 'break_minutes' then
      if p_new_value::integer < 0 or p_new_value::integer > 240 then raise exception 'Break must be between 0 and 240 minutes.'; end if;
    else
      perform p_new_value::timestamptz;
    end if;
  exception when invalid_text_representation or datetime_field_overflow or invalid_datetime_format then
    raise exception 'The corrected value is not valid.';
  end;
  if exists (select 1 from attendance_corrections where attendance_id = att.id and field = p_field and status = 'Pending') then
    raise exception 'A correction for this field is already pending.';
  end if;
  old_v := case p_field when 'clock_in' then att.clock_in::text when 'clock_out' then att.clock_out::text
                        else att.break_minutes::text end;
  insert into attendance_corrections (attendance_id, employee_id, field, old_value, new_value, reason)
  values (att.id, emp, p_field, old_v, p_new_value, btrim(p_reason)) returning * into rec;
  return rec;
end $function$;

REVOKE ALL ON FUNCTION "public"."request_correction"(uuid, text, text, text) FROM PUBLIC, "anon";

CREATE OR REPLACE FUNCTION public.request_overtime (
  p_attendance_id uuid,
  p_hours         numeric,
  p_reason        text
)
  RETURNS public.overtime
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare emp uuid := current_employee_id(); att attendance; rec overtime;
begin
  if p_hours is null or p_hours <= 0 or p_hours > 12 then raise exception 'Hours must be between 0 and 12.'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'Enter a reason.'; end if;
  select * into att from attendance where id = p_attendance_id and employee_id = emp;
  if att.id is null then raise exception 'Attendance record not found.'; end if;
  if att.clock_out is null then raise exception 'Clock out before requesting overtime.'; end if;
  insert into overtime (employee_id, attendance_id, work_date, hours, reason)
  values (emp, att.id, (att.clock_in at time zone 'Africa/Johannesburg')::date, p_hours, btrim(p_reason))
  returning * into rec;
  return rec;
exception when unique_violation then
  raise exception 'Overtime was already requested for that day.';
end $function$;

REVOKE ALL ON FUNCTION "public"."request_overtime"(uuid, numeric, text) FROM PUBLIC, "anon";

CREATE OR REPLACE FUNCTION public.resolve_employee_email (
  p_code text
)
  RETURNS text
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
  select case
    when p_code like '%@%' then p_code
    else (select email from public.employees
           where employee_code = upper(trim(p_code)) and is_active)
  end;
$function$;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
  RETURNS event_trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
DECLARE
  cmd record;
  tbl name;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        SELECT c.relname INTO tbl FROM pg_catalog.pg_class c WHERE c.oid = cmd.objid;
        EXECUTE format('alter table if exists %I.%I enable row level security', cmd.schema_name, tbl);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.write_audit()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
begin
  insert into audit_log (actor_id, entity, entity_id, action, details)
  values (current_employee_id(), tg_table_name, new.id, tg_op,
          case when tg_op = 'UPDATE' then jsonb_build_object('old', to_jsonb(old), 'new', to_jsonb(new))
               else to_jsonb(new) end);
  return null;
end $function$;

ALTER TABLE "public"."attendance_corrections"
  ADD CONSTRAINT "attendance_corrections_attendance_id_fkey" FOREIGN KEY (attendance_id) REFERENCES public.attendance(id);

ALTER TABLE "public"."employees"
  ADD CONSTRAINT "employees_department_id_fkey" FOREIGN KEY (department_id) REFERENCES public.departments(id);

ALTER TABLE "public"."attendance"
  ADD CONSTRAINT "attendance_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES public.employees(id);

ALTER TABLE "public"."attendance_corrections"
  ADD CONSTRAINT "attendance_corrections_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES public.employees(id);

ALTER TABLE "public"."attendance_corrections"
  ADD CONSTRAINT "attendance_corrections_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES public.employees(id);

ALTER TABLE "public"."audit_log"
  ADD CONSTRAINT "audit_log_actor_id_fkey" FOREIGN KEY (actor_id) REFERENCES public.employees(id);

ALTER TABLE "public"."employees"
  ADD CONSTRAINT "employees_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."overtime"
  ADD CONSTRAINT "overtime_attendance_id_fkey" FOREIGN KEY (attendance_id) REFERENCES public.attendance(id);

ALTER TABLE "public"."overtime"
  ADD CONSTRAINT "overtime_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES public.employees(id);

ALTER TABLE "public"."overtime"
  ADD CONSTRAINT "overtime_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES public.employees(id);

CREATE INDEX attendance_corrections_status_idx ON public.attendance_corrections USING btree (status);

CREATE INDEX attendance_employee_id_clock_in_idx ON public.attendance USING btree (employee_id, clock_in DESC);

CREATE INDEX audit_log_created_at_idx ON public.audit_log USING btree (created_at DESC);

CREATE UNIQUE INDEX one_open_record_per_employee ON public.attendance USING btree (employee_id)
  WHERE (clock_out IS NULL);

CREATE INDEX overtime_status_idx ON public.overtime USING btree (status);

CREATE TRIGGER audit_attendance
  AFTER INSERT OR UPDATE ON public.attendance
  FOR EACH ROW
  EXECUTE FUNCTION public.write_audit();

CREATE TRIGGER audit_corrections
  AFTER INSERT OR UPDATE ON public.attendance_corrections
  FOR EACH ROW
  EXECUTE FUNCTION public.write_audit();

CREATE TRIGGER correction_apply
  AFTER UPDATE ON public.attendance_corrections
  FOR EACH ROW
  WHEN ((old.status IS DISTINCT FROM new.status))
  EXECUTE FUNCTION public.apply_decision();

CREATE TRIGGER correction_review
  BEFORE UPDATE ON public.attendance_corrections
  FOR EACH ROW
  WHEN ((old.status IS DISTINCT FROM new.status))
  EXECUTE FUNCTION public.guard_review();

CREATE TRIGGER audit_employees
  AFTER INSERT OR UPDATE ON public.employees
  FOR EACH ROW
  EXECUTE FUNCTION public.write_audit();

CREATE TRIGGER audit_overtime
  AFTER INSERT OR UPDATE ON public.overtime
  FOR EACH ROW
  EXECUTE FUNCTION public.write_audit();

CREATE TRIGGER overtime_apply
  AFTER UPDATE ON public.overtime
  FOR EACH ROW
  WHEN ((old.status IS DISTINCT FROM new.status))
  EXECUTE FUNCTION public.apply_decision();

CREATE TRIGGER overtime_review
  BEFORE UPDATE ON public.overtime
  FOR EACH ROW
  WHEN ((old.status IS DISTINCT FROM new.status))
  EXECUTE FUNCTION public.guard_review();

CREATE POLICY "att_admin" ON "public"."attendance"
  FOR ALL
  TO "authenticated"
  USING ((public.current_employee_role() = 'admin'::text))
  WITH CHECK ((public.current_employee_role() = 'admin'::text));

CREATE POLICY "att_read" ON "public"."attendance"
  FOR SELECT
  TO "authenticated"
  USING (((employee_id = public.current_employee_id()) OR (public.current_employee_role() = ANY (ARRAY['supervisor'::text, 'admin'::text]))));

CREATE POLICY "cor_read" ON "public"."attendance_corrections"
  FOR SELECT
  TO "authenticated"
  USING (((employee_id = public.current_employee_id()) OR (public.current_employee_role() = ANY (ARRAY['supervisor'::text, 'admin'::text]))));

CREATE POLICY "cor_review" ON "public"."attendance_corrections"
  FOR UPDATE
  TO "authenticated"
  USING ((public.current_employee_role() = ANY (ARRAY['supervisor'::text, 'admin'::text])))
  WITH CHECK ((public.current_employee_role() = ANY (ARRAY['supervisor'::text, 'admin'::text])));

CREATE POLICY "audit_read" ON "public"."audit_log"
  FOR SELECT
  TO "authenticated"
  USING ((public.current_employee_role() = 'admin'::text));

CREATE POLICY "dept_admin" ON "public"."departments"
  FOR ALL
  TO "authenticated"
  USING ((public.current_employee_role() = 'admin'::text))
  WITH CHECK ((public.current_employee_role() = 'admin'::text));

CREATE POLICY "dept_read" ON "public"."departments"
  FOR SELECT
  TO "authenticated"
  USING (true);

CREATE POLICY "emp_admin" ON "public"."employees"
  FOR ALL
  TO "authenticated"
  USING ((public.current_employee_role() = 'admin'::text))
  WITH CHECK ((public.current_employee_role() = 'admin'::text));

CREATE POLICY "emp_read" ON "public"."employees"
  FOR SELECT
  TO "authenticated"
  USING (((user_id = auth.uid()) OR (public.current_employee_role() = ANY (ARRAY['supervisor'::text, 'admin'::text]))));

CREATE POLICY "ot_read" ON "public"."overtime"
  FOR SELECT
  TO "authenticated"
  USING (((employee_id = public.current_employee_id()) OR (public.current_employee_role() = ANY (ARRAY['supervisor'::text, 'admin'::text]))));

CREATE POLICY "ot_review" ON "public"."overtime"
  FOR UPDATE
  TO "authenticated"
  USING ((public.current_employee_role() = ANY (ARRAY['supervisor'::text, 'admin'::text])))
  WITH CHECK ((public.current_employee_role() = ANY (ARRAY['supervisor'::text, 'admin'::text])));

CREATE EVENT TRIGGER "ensure_rls"
  ON ddl_command_end
  WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
  EXECUTE FUNCTION "public"."rls_auto_enable"();

GRANT EXECUTE ON FUNCTION "public"."admin_create_employee"(text, text, text, text, uuid) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."admin_create_employee"(text, text, text, text, uuid) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."admin_create_employee"(text, text, text, text, uuid) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."admin_create_employee"(text, text, text, text, uuid) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."admin_create_employee"(text, text, text, text, uuid, text) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."admin_create_employee"(text, text, text, text, uuid, text) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."admin_create_employee"(text, text, text, text, uuid, text) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."admin_create_employee"(text, text, text, text, uuid, text) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."admin_update_employee"(uuid, text, text, text, text, uuid, boolean) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."admin_update_employee"(uuid, text, text, text, text, uuid, boolean) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."admin_update_employee"(uuid, text, text, text, text, uuid, boolean) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."admin_update_employee"(uuid, text, text, text, text, uuid, boolean) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."apply_decision"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."apply_decision"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."apply_decision"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."apply_decision"() TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."clock_in"() TO "authenticated";

REVOKE ALL ON FUNCTION "public"."clock_in"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."clock_in"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."clock_in"() TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."clock_out"() TO "authenticated";

REVOKE ALL ON FUNCTION "public"."clock_out"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."clock_out"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."clock_out"() TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."current_employee_id"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."current_employee_id"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."current_employee_id"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."current_employee_id"() TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."current_employee_role"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."current_employee_role"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."current_employee_role"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."current_employee_role"() TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."guard_review"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."guard_review"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."guard_review"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."guard_review"() TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."login_lookup"(text) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."login_lookup"(text) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."login_lookup"(text) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."login_lookup"(text) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."record_break"(integer) TO "authenticated";

REVOKE ALL ON FUNCTION "public"."record_break"(integer) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."record_break"(integer) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."record_break"(integer) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."request_correction"(uuid, text, text, text) TO "authenticated";

REVOKE ALL ON FUNCTION "public"."request_correction"(uuid, text, text, text) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."request_correction"(uuid, text, text, text) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."request_correction"(uuid, text, text, text) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."request_overtime"(uuid, numeric, text) TO "authenticated";

REVOKE ALL ON FUNCTION "public"."request_overtime"(uuid, numeric, text) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."request_overtime"(uuid, numeric, text) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."request_overtime"(uuid, numeric, text) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."resolve_employee_email"(text) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."resolve_employee_email"(text) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."resolve_employee_email"(text) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."resolve_employee_email"(text) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."rls_auto_enable"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."rls_auto_enable"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."rls_auto_enable"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."rls_auto_enable"() TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."write_audit"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."write_audit"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."write_audit"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."write_audit"() TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."attendance" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."attendance" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."attendance" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."attendance" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."attendance_corrections" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."attendance_corrections" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."attendance_corrections" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."attendance_corrections" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."audit_log" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."audit_log" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."audit_log" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."audit_log" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."departments" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."departments" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."departments" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."departments" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."employees" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."employees" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."employees" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."employees" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."overtime" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."overtime" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."overtime" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."overtime" TO "service_role";

