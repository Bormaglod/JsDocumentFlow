--
-- PostgreSQL database dump
--

-- Dumped from database version 10.2
-- Dumped by pg_dump version 10.5

-- Started on 2018-12-19 23:43:33

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 3094 (class 1262 OID 51397)
-- Name: workflow_enterprise; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE workflow_enterprise WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Russian_Russia.1251' LC_CTYPE = 'Russian_Russia.1251';


ALTER DATABASE workflow_enterprise OWNER TO postgres;

\connect workflow_enterprise

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 12924)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 3096 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 2 (class 3079 OID 51419)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 3097 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 723 (class 1247 OID 51987)
-- Name: access_right; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.access_right AS ENUM (
    'select',
    'insert',
    'delete',
    'change',
    'transition',
    'execute'
);


ALTER TYPE public.access_right OWNER TO postgres;

--
-- TOC entry 722 (class 1247 OID 52020)
-- Name: access_value; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.access_value AS ENUM (
    'allow',
    'deny'
);


ALTER TYPE public.access_value OWNER TO postgres;

--
-- TOC entry 732 (class 1247 OID 77765)
-- Name: addon_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.addon_type AS (
	id uuid,
	status_id bigint,
	status_name character varying(255),
	code character varying(20),
	name character varying(255),
	version integer,
	deescription text,
	status_picture_id uuid
);


ALTER TYPE public.addon_type OWNER TO postgres;

--
-- TOC entry 721 (class 1247 OID 53176)
-- Name: command_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.command_type AS ENUM (
    'view_table',
    'edit_record'
);


ALTER TYPE public.command_type OWNER TO postgres;

--
-- TOC entry 711 (class 1247 OID 69564)
-- Name: contractor_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.contractor_type AS (
	id uuid,
	status_id bigint,
	status_name character varying(255),
	code character varying(20),
	name character varying(255),
	short_name character varying(50),
	full_name character varying(150),
	inn numeric(12,0),
	kpp numeric(9,0),
	ogrn numeric(13,0),
	okpo numeric(8,0),
	okopf_id uuid,
	okopf_name character varying(255),
	parent_id uuid,
	status_picture_id uuid
);


ALTER TYPE public.contractor_type OWNER TO postgres;

--
-- TOC entry 714 (class 1247 OID 77752)
-- Name: group_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.group_type AS (
	id uuid,
	status_id bigint,
	status_name character varying(255),
	code character varying(20),
	name character varying(255),
	parent_id uuid,
	status_picture_id uuid
);


ALTER TYPE public.group_type OWNER TO postgres;

--
-- TOC entry 677 (class 1247 OID 51546)
-- Name: kind_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.kind_type AS ENUM (
    'directory',
    'document'
);


ALTER TYPE public.kind_type OWNER TO postgres;

--
-- TOC entry 729 (class 1247 OID 77761)
-- Name: okopf_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.okopf_type AS (
	id uuid,
	status_id bigint,
	status_name character varying(255),
	code character varying(20),
	name character varying(255),
	status_picture_id uuid
);


ALTER TYPE public.okopf_type OWNER TO postgres;

--
-- TOC entry 735 (class 1247 OID 77790)
-- Name: picture_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.picture_type AS (
	id uuid,
	code character varying(20),
	name character varying(255),
	size16 text,
	size32 text,
	fa_name character varying(20),
	img_name character varying(255),
	note text,
	parent_id uuid
);


ALTER TYPE public.picture_type OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 52018)
-- Name: access_check(uuid, public.access_right, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.access_check(object_id uuid, access_value public.access_right, user_name character varying DEFAULT NULL::character varying) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  cid uuid;
  parent_id uuid;
  avalue access_value;
begin
  user_name = coalesce(user_name, session_user);
  select id into cid from client where pg_name = user_name;
  
  loop
    with cte as
    (
      select coalesce(directory_id, coalesce(document_id, coalesce(kind_id, changing_status_id))) obj_id,
             value
        from access_list
        where client_id = cid and access = access_value
    )
    select value
      into avalue
      from cte
      where obj_id = object_id;
      
    exit when avalue is not null;
     
    select client.parent_id into cid from client where id = cid;
    exit when cid is null;
  end loop;
    
  -- доступ разрешен, если права доступа не установлены или установлены в ALLOW
  return avalue is null or avalue = 'allow';
end;
$$;


ALTER FUNCTION public.access_check(object_id uuid, access_value public.access_right, user_name character varying) OWNER TO postgres;

--
-- TOC entry 271 (class 1255 OID 77766)
-- Name: addon_select(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.addon_select(did uuid DEFAULT public.uuid_nil()) RETURNS SETOF public.addon_type
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  user_name varchar;
  mrec addon_type;
begin
  did = coalesce(did, uuid_nil());
  
  select session_user into user_name;
  if access_check(get_constant('kind.addon')::uuid, 'select', user_name) then
    for mrec in
      select d.id, d.status_id, s.note, d.code, d.name, a.version, a.description, s.picture_id
        from directory d
          left join status s on (d.status_id = s.id)
          left join addon a on (d.id = a.id)
        where 
          kind_id = get_constant('kind.addon')::uuid and
          did in (uuid_nil(), d.id)
    loop
      return next mrec;
    end loop;
  end if;
end;
$$;


ALTER FUNCTION public.addon_select(did uuid) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 77758)
-- Name: contractor_select(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.contractor_select(did uuid DEFAULT public.uuid_nil(), dparent uuid DEFAULT public.uuid_nil()) RETURNS SETOF public.contractor_type
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  user_name varchar;
  mrec contractor_type;
  id_type integer;
begin
  did = coalesce(did, uuid_nil());
  dparent = coalesce(dparent, uuid_nil());
  
  select session_user into user_name;
  if access_check(get_constant('kind.contractor')::uuid, 'select', user_name) then
    if (did != uuid_nil()) then
      id_type = 0;
    else
      id_type = 1;
    end if;
  
    for mrec in
      select d.id, d.status_id, s.note, d.code, d.name, c.short_name, c.full_name, c.inn, c.kpp, c.ogrn, c.okpo, c.okopf_id, o.name as okopf_name, d.parent_id, s.picture_id
        from directory d
          left join status s on (d.status_id = s.id)
          left join contractor c on (d.id = c.id)
          left join directory o on (o.id = c.okopf_id)
        where 
          d.kind_id = get_constant('kind.contractor')::uuid and
          (
          	case id_type
              when 0 then did in (uuid_nil(), d.id)
              when 1 then 
                case dparent
                  when uuid_nil() then d.parent_id is null
                  else dparent = d.parent_id
                end
            end
          )
    loop
      return next mrec;
    end loop;
  end if;
end;
$$;


ALTER FUNCTION public.contractor_select(did uuid, dparent uuid) OWNER TO postgres;

--
-- TOC entry 259 (class 1255 OID 77804)
-- Name: contractor_test_inn(numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.contractor_test_inn(inn numeric) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
   inn_arr integer[];
   k integer[] := '{ 2, 4, 10, 3, 5, 9, 4, 6, 8 }';
   k1 integer[] := '{ 7, 2, 4, 10, 3, 5, 9, 4, 6, 8 }';
   k2 integer[] := '{3, 7, 2, 4, 10, 3, 5, 9, 4, 6, 8 }';
begin
   inn_arr := string_to_array(inn::character varying, NULL)::integer[];

   if (array_length(inn_arr, 1) != 10 and array_length(inn_arr, 1) != 12) then
      return false;
   end if;

   if (control_value(inn_arr, k, 11) = inn_arr[10]) then
      if (array_length(inn_arr, 1) = 12) then
         return control_value(inn_arr, k1, 11) == inn_arr[11] && control_value(inn_arr, k2, 11) == inn_arr[12];
      end if;
		
      return true;
   end if;

   return false;
end;
$$;


ALTER FUNCTION public.contractor_test_inn(inn numeric) OWNER TO postgres;

--
-- TOC entry 274 (class 1255 OID 77808)
-- Name: contractor_test_okpo(numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.contractor_test_okpo(okpo numeric) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
   okpo_arr integer[];
   k1 integer[] := '{ 1, 2, 3, 4, 5, 6, 7 }';
   k2 integer[] := '{ 3, 4, 5, 6, 7, 8, 9 }';
   c integer;
begin
   okpo_arr := string_to_array(okpo::character varying, NULL)::integer[];
   if (array_length(okpo_arr, 1) < 8) then
      return false;
   end if;
	
   c := control_value(okpo_arr, k1, 11, false);
   if (c > 9) then
      c := control_value(okpo_arr, k2, 11);
   end if;

   return c = okpo_arr[8];
end;
$$;


ALTER FUNCTION public.contractor_test_okpo(okpo numeric) OWNER TO postgres;

--
-- TOC entry 222 (class 1255 OID 77802)
-- Name: control_sum(integer[], integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.control_sum(source integer[], coeff integer[]) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
   sum integer;
   m integer;
begin
   m := min_int(array_length(source, 1), array_length(coeff, 1));

   sum := 0;
   for i in 1 .. m loop
      sum := sum + source[i] * coeff[i];
   end loop;
	
   return sum;
end;
$$;


ALTER FUNCTION public.control_sum(source integer[], coeff integer[]) OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 77803)
-- Name: control_value(integer[], integer[], integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.control_value(source integer[], coeff integer[], divider integer, test10 boolean DEFAULT true) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
   r integer;
begin
   r := control_sum(source, coeff) % divider;
   if (test10 and r = 10) then
      r := 0;
   end if;

   return r;
end;
$$;


ALTER FUNCTION public.control_value(source integer[], coeff integer[], divider integer, test10 boolean) OWNER TO postgres;

--
-- TOC entry 269 (class 1255 OID 51941)
-- Name: dir_change_status(uuid, bigint, boolean, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dir_change_status(dir_id uuid, new_status_id bigint, auto boolean DEFAULT false, note character varying DEFAULT NULL::character varying) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  cid uuid;
  sid bigint;
  locked_name character varying(20);
  date_lock timestamp with time zone;
  cur_status bigint;
begin
  select id into cid from client where pg_name = session_user;

  select status_id, client.name, date_locked
    into cur_status, locked_name, date_lock
    from directory
      left join client on (client_locked_id = client.id)
    where directory.id = dir_id;
    
  if locked_name is not null then
    raise 'Запись заблокирована пользователем % в %', locked_name, date_lock;
  end if;
  
  if (new_status_id != cur_status) then
    perform dir_check_status(cid, dir_id, cur_status, new_status_id, auto);
    
    with rows as(
      insert into history (directory_id, status_from_id, status_to_id, client_id, auto, note)
        values (dir_id, cur_status, new_status_id, cid, auto, note) returning id
    )
    update directory
      set
        status_id = new_status_id,
        history_id = (select id from rows)
      where id = dir_id;

    perform dir_complete_status(cid, dir_id, cur_status, new_status_id, auto);
  end if;
end;
$$;


ALTER FUNCTION public.dir_change_status(dir_id uuid, new_status_id bigint, auto boolean, note character varying) OWNER TO postgres;

--
-- TOC entry 276 (class 1255 OID 51939)
-- Name: dir_check_status(uuid, uuid, bigint, bigint, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dir_check_status(client_id uuid, dir_id uuid, status_from bigint, status_to bigint, auto boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin

end;
$$;


ALTER FUNCTION public.dir_check_status(client_id uuid, dir_id uuid, status_from bigint, status_to bigint, auto boolean) OWNER TO postgres;

--
-- TOC entry 237 (class 1255 OID 51940)
-- Name: dir_complete_status(uuid, uuid, bigint, bigint, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dir_complete_status(client_id uuid, dir_id uuid, status_from bigint, status_to bigint, auto boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin

end;
$$;


ALTER FUNCTION public.dir_complete_status(client_id uuid, dir_id uuid, status_from bigint, status_to bigint, auto boolean) OWNER TO postgres;

--
-- TOC entry 256 (class 1255 OID 53186)
-- Name: get_command(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_command(cmd_id uuid) RETURNS TABLE(code character varying, name character varying, refresh_dataset boolean, refresh_record boolean, refresh_menu boolean, command_type public.command_type, schema_data json)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  user_name varchar;
  mrec record;
begin
  select session_user into user_name;
  for mrec in
    select d.id, d.code, d.name, c.refresh_dataset, c.refresh_record, c.refresh_menu, c.command_type, c.schema_data
      from directory d
        join command c on (c.id = d.id)
      where 
        d.id = cmd_id
  loop
    if access_check(mrec.id, 'execute', user_name) then
      code = mrec.code;
      name = mrec.name;
      refresh_dataset = mrec.refresh_dataset;
      refresh_record = mrec.refresh_record;
      refresh_menu = mrec.refresh_menu;
      command_type = mrec.command_type;
      schema_data = mrec.schema_data;
      return next;
    end if;
  end loop;
end;
$$;


ALTER FUNCTION public.get_command(cmd_id uuid) OWNER TO postgres;

--
-- TOC entry 264 (class 1255 OID 52126)
-- Name: get_constant(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_constant(const_name character varying) RETURNS character varying
    LANGUAGE sql IMMUTABLE
    AS $$
select value from constants where key = const_name;
$$;


ALTER FUNCTION public.get_constant(const_name character varying) OWNER TO postgres;

--
-- TOC entry 225 (class 1255 OID 69559)
-- Name: get_info_table(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_info_table(code_table character varying) RETURNS TABLE(id uuid, name character varying, title character varying, is_system boolean, has_group boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  user_name varchar;
  mrec record;
begin
  select session_user into user_name;
  for mrec in
    select k.id, k.name, k.title, k.is_system, k.has_group
      from kind k
      where k.code = code_table
  loop
    if access_check(mrec.id, 'select', user_name) then
      id = mrec.id;
      name = mrec.name;
      title = mrec.title;
      is_system = mrec.is_system;
      has_group = mrec.has_group;
      return next;
    end if;
  end loop;
end;
$$;


ALTER FUNCTION public.get_info_table(code_table character varying) OWNER TO postgres;

--
-- TOC entry 226 (class 1255 OID 77755)
-- Name: group_create(uuid, character varying, character varying, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.group_create(kind_directory uuid, group_code character varying, group_name character varying, parent uuid DEFAULT NULL::uuid) RETURNS public.group_type
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  did uuid;
  mrec group_type;
begin
  insert into directory (status_id, kind_id, code, name, parent_id) 
    values (500, kind_directory, group_code, group_name, parent)
    returning id into did;
    
  select d.id, d.status_id, s.note, d.code, d.name, d.parent_id, s.picture_id
    into mrec
    from directory d
      left join status s on (d.status_id = s.id)
    where 
      d.id = did;
    
  return mrec;
end;
$$;


ALTER FUNCTION public.group_create(kind_directory uuid, group_code character varying, group_name character varying, parent uuid) OWNER TO postgres;

--
-- TOC entry 228 (class 1255 OID 77800)
-- Name: group_delete(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.group_delete(did uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  status bigint;
begin
  if (did is null) then
    raise 'Не указан идентификатор группы';
  end if;
  
  select d.status_id into status from directory d where d.id = did;
  if (status is null) then
    raise 'Запись с указанным идентификатором группы не найдена';
  end if;
  
  if (status != 500) then
    raise 'Запись с указанным идентификатором группы не является группой';
  end if;
  
  delete from directory where id = did;
end;
$$;


ALTER FUNCTION public.group_delete(did uuid) OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 77757)
-- Name: group_update(uuid, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.group_update(group_id uuid, group_code character varying, group_name character varying) RETURNS public.group_type
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  mrec group_type;
begin
  update directory
    set code = group_code,
    	name = group_name
    where id = group_id;
    
  select d.id, d.status_id, s.note, d.code, d.name, d.parent_id, s.picture_id
    into mrec
    from directory d
      left join status s on (d.status_id = s.id)
    where 
      d.id = group_id;
    
  return mrec;
end;
$$;


ALTER FUNCTION public.group_update(group_id uuid, group_code character varying, group_name character varying) OWNER TO postgres;

--
-- TOC entry 267 (class 1255 OID 52170)
-- Name: login(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.login() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  cid uuid;
begin
  perform logout();

  select id into cid from client where pg_name = session_user;
  insert into log (client_id, login_time) values (cid, current_timestamp);
end;
$$;


ALTER FUNCTION public.login() OWNER TO postgres;

--
-- TOC entry 224 (class 1255 OID 52171)
-- Name: logout(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.logout() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  cid uuid;
  log_id bigint;
begin
  select id into cid from client where pg_name = session_user;
  select id into log_id from log where client_id = cid and logout_time is null;
  
  if (log_id is not null) then
    update log set logout_time = current_timestamp where id = log_id;
  end if;
end;
$$;


ALTER FUNCTION public.logout() OWNER TO postgres;

--
-- TOC entry 231 (class 1255 OID 77801)
-- Name: min_int(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.min_int(left_value integer, right_value integer) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
   m integer;
begin
   if (left_value < right_value) then
      m = left_value;
   else
      m = right_value;
   end if;

   return m;
end;
$$;


ALTER FUNCTION public.min_int(left_value integer, right_value integer) OWNER TO postgres;

--
-- TOC entry 262 (class 1255 OID 77762)
-- Name: okopf_select(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.okopf_select(did uuid DEFAULT public.uuid_nil()) RETURNS SETOF public.okopf_type
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  user_name varchar;
  mrec okopf_type;
begin
  did = coalesce(did, uuid_nil());
  
  select session_user into user_name;
  if access_check(get_constant('kind.okopf')::uuid, 'select', user_name) then
    for mrec in
      select d.id, d.status_id, s.note, d.code, d.name, s.picture_id
        from directory d
          left join status s on (d.status_id = s.id)
        where 
          kind_id = get_constant('kind.okopf')::uuid and
          did in (uuid_nil(), d.id)
    loop
      return next mrec;
    end loop;
  end if;
end;
$$;


ALTER FUNCTION public.okopf_select(did uuid) OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 77791)
-- Name: picture_select(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.picture_select(did uuid DEFAULT public.uuid_nil()) RETURNS SETOF public.picture_type
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  user_name varchar;
  mrec picture_type;
begin
  did = coalesce(did, uuid_nil());
  
  select session_user into user_name;
  if access_check(get_constant('kind.picture')::uuid, 'select', user_name) then
    for mrec in
      select d.id, d.code, d.name, p.size16, p.size32, p.fa_name, p.img_name, p.note, d.parent_id
        from directory d
          left join picture p on (d.id = p.id)
        where 
          kind_id = get_constant('kind.picture')::uuid and
          did in (uuid_nil(), d.id)
    loop
      return next mrec;
    end loop;
  end if;
end;
$$;


ALTER FUNCTION public.picture_select(did uuid) OWNER TO postgres;

--
-- TOC entry 273 (class 1255 OID 61366)
-- Name: select_menu(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_menu() RETURNS TABLE(id uuid, code character varying, name character varying, parent_id uuid, command_id uuid, command_type public.command_type, picture_16 text, picture_32 text, fa_name character varying, order_index integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  name varchar;
begin
  select session_user into name;
  return query select * from select_menu_int(name);
end;
$$;


ALTER FUNCTION public.select_menu() OWNER TO postgres;

--
-- TOC entry 265 (class 1255 OID 61365)
-- Name: select_menu_int(character varying, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_menu_int(user_name character varying DEFAULT NULL::character varying, parent_menu uuid DEFAULT public.uuid_nil()) RETURNS TABLE(id uuid, code character varying, name character varying, parent_id uuid, command_id uuid, command_type public.command_type, picture_16 text, picture_32 text, fa_name character varying, order_index integer)
    LANGUAGE plpgsql
    AS $$
declare
  mrec record;
begin
  for mrec in
    select d.id, d.code, d.name, d.parent_id, d.picture_id, m.command_id, c.command_type, p.size16, p.size32, p.fa_name, m.order_index
      from directory d
        join menu m on (m.id = d.id)
        left join command c on (c.id = m.command_id)
        left join picture p on (p.id = d.picture_id)
      where 
        d.kind_id = get_constant('kind.menu')::uuid and
        coalesce(d.parent_id, uuid_nil()) = parent_menu
      order by m.order_index, d.name
  loop
    if access_check(mrec.id, 'select', user_name) then
      id = mrec.id;
      code = mrec.code;
      name = mrec.name;
      parent_id = mrec.parent_id;
      command_id = mrec.command_id;
      command_type = mrec.command_type;
      picture_16 = mrec.size16;
      picture_32 = mrec.size32;
      fa_name = mrec.fa_name;
      order_index = mrec.order_index;
      return next;
      
      return query select * from select_menu_int(user_name, id);
    end if;
  end loop;
end;
$$;


ALTER FUNCTION public.select_menu_int(user_name character varying, parent_menu uuid) OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 52079)
-- Name: tr_access_list_check(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_access_list_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  i integer;
begin
  i = 0;
  if (new.directory_id is not null) then
    i = i + 1;
  end if;
  
  if (new.document_id is not null) then
    i = i + 1;
  end if;
  
  if (new.kind_id is not null) then
    i = i + 1;
  end if;
  
  if (new.changing_status_id is not NULL) then
    i = i + 1;
  end if;
  
  if (i > 1) then
    raise 'Необходимо указать только один объект для определения права доступа.';
  end if;

  return new;
end;
$$;


ALTER FUNCTION public.tr_access_list_check() OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 61363)
-- Name: tr_contractor_init(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_contractor_init() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.short_name is null then
    select name into new.short_name from directory where directory.id = new.id;
  end if;
  
  return new;
end;
$$;


ALTER FUNCTION public.tr_contractor_init() OWNER TO postgres;

--
-- TOC entry 258 (class 1255 OID 77805)
-- Name: tr_contractor_test_codes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_contractor_test_codes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  bik numeric(9,0);
  code numeric;
begin
  code = coalesce(new.inn, 0);  
  if ((code > 0) and (not contractor_test_inn(code))) then
    raise exception 'Некорректное значение ИНН';
  end if;

  code = coalesce(new.okpo, 0);
  if ((code > 0) and (not contractor_test_okpo(code))) then
    raise exception 'Некорректное значение ОКПО';
  end if;

   --if ((new.bank_id is not null) and (new.account is not null)) then
   --   select bank.bik
   --      into bik
   --      from bank 
   --      where bank.id = new.bank_id;
   --   if (not test_current_account(new.account, bik)) then
   --      raise exception 'Некорректное значение расч. счета';
   --   end if;
   --end if;

   return new;
end;
$$;


ALTER FUNCTION public.tr_contractor_test_codes() OWNER TO postgres;

--
-- TOC entry 266 (class 1255 OID 52128)
-- Name: tr_directory_ins_prop(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_directory_ins_prop() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  tname character varying(255);
begin
  if (new.status_id != 500) then
    select code into tname from kind where id = new.kind_id;
    if exists(select table_name from information_schema.tables where table_schema = 'public' and table_name = tname) then
      execute 'insert into ' || tname || ' (id) values (' || quote_literal(new.id) || ')';
    end if;
  end if;
  
  return new;
end;
$$;


ALTER FUNCTION public.tr_directory_ins_prop() OWNER TO postgres;

--
-- TOC entry 270 (class 1255 OID 51960)
-- Name: tr_doc_info_change_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_doc_info_change_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  did uuid;
  status_from bigint; 
  status_to bigint;
begin
  if (new.status_id != old.status_id) then

    select status_from_id, 
           status_to_id, 
           case 
             when TG_TABLE_NAME = 'directory' then directory_id
             when TG_TABLE_NAME = 'document' then document_id
             else uuid_nil()
           end
      into status_from, status_to, did
      from history
      where id = new.history_id;

    did = coalesce(did, uuid_nil());
    if (new.id != did) then
      raise 'Некорректное значение справочника в истории переводов';
    end if;

    status_from = coalesce(status_from, 0);
    status_to = coalesce(status_to, 0);
    if (old.status_id != status_from) or (new.status_id != status_to) then
      raise 'Для корректного перевода воспользуйтесь процедурой dir_change_status()';
    end if;
  end if;

  return new;
end;
$$;


ALTER FUNCTION public.tr_doc_info_change_status() OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 51976)
-- Name: tr_doc_info_check_access(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_doc_info_check_access() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  current_type kind_type;
  is_valid boolean;
  parent_code character varying(20);
  parent_name character varying(255);
  parent_status bigint;
  changing_id uuid;
begin
  select type_view into current_type from kind where id = new.kind_id;
  case
    when tg_table_name = 'directory' then
      is_valid = current_type = 'directory';
    when tg_table_name = 'document' then
      is_valid = current_type = 'document';
    else
      is_valid = false;
  end case;

  if not is_valid then
    raise 'Неверный тип добавляемого документа/справочника.';
  end if;

  if tg_op = 'UPDATE' then
    -- проверим право пользователя изменять документ
    if not access_check(new.kind_id, 'change') then
      raise 'У вас не права для изменения документа/справочника';
    end if;
    
    if not access_check(new.id, 'change') then
      raise 'У вас не права для изменения этого документа/справочника';
    end if;
    
    -- проверим право пользователя менять состояние документа
    if new.status_id != old.status_id then
      select c.id 
        into changing_id 
        from kind k
          join transition t on (k.transition_id = t.id)
          join changing_status c on (c.transition_id = t.id)
        where
          k.id = new.kind_id and
          c.status_from_id = old.status_id and
          c.status_to_id = new.status_id;
          
      if changing_id is null then
        raise 'Переход документа из состояния "%" в состояние "%" невозможен.',
          (select note from status where id = old.status_id),
          (select note from status where id = new.status_id);
      end if;
      
      if not access_check(changing_id, 'transition') then
        raise 'У вас нет права для изменения состояния документа из "%" в "%".',
          (select note from status where id = old.status_id),
          (select note from status where id = new.status_id);
      end if;
    end if;
    
    if new.kind_id != old.kind_id then
        raise 'Тип документа менять нельзя.';
    end if;
  end if;
  
  if tg_op = 'INSERT' then
    if not access_check(new.kind_id, 'insert') then
      raise 'У вас не права для для добавления документа/справочника';
    end if;
  end if;
  
  if tg_table_name = 'directory' then
    if new.parent_id is not null then
      select code, name, status_id
        into parent_code, parent_name, parent_status
        from directory
        where id = new.parent_id;

      if parent_status != 500 then
        parent_name = coalesce(parent_name, '');
        if parent_name = '' then
          parent_name = parent_code;
        end if;

        raise 'Запись справочника "%" не является группой.', parent_name;
      end if;
    end if;
  end if;

  return new;
end;
$$;


ALTER FUNCTION public.tr_doc_info_check_access() OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 51971)
-- Name: tr_doc_info_check_remove(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_doc_info_check_remove() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  tv kind_type;
  sys boolean;
  status_id bigint;
  name_value character varying(20);
begin
  select type_view, is_system, start_status_id into tv, sys, status_id from kind where id = old.kind_id;
  
  name_value = case
    when tv = 'directory' then 'Элемент справочника'
    when tv = 'document' then 'Документ'
  end;
  
  if (select administrator from client where pg_name = session_user) = false then
    if sys then
      raise '% (%) может удалить только администратор.', name_value, old.code;
    end if;
  end if;
  
  if not access_check(old.kind_id, 'delete') then
    raise 'У вас не права для удаления документа/справочника';
  end if;
  
  if not access_check(old.id, 'delete') then
    raise 'У вас не права для удаления этого документа/справочника';
  end if;
  
  if (old.status_id != status_id and old.status_id != 500) then
    raise '% (id = %) можно удалить только в состоянии "%"',
      name_value,
      old.id,
      (select note from status where id = status_id);
  end if;

  return old;
end;
$$;


ALTER FUNCTION public.tr_doc_info_check_remove() OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 51964)
-- Name: tr_doc_info_init(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_doc_info_init() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  client_id uuid;
  start_status bigint;
  grp boolean;
begin
  select id into client_id from client where pg_name = session_user;

  new.client_created_id = client_id;
  new.date_created = current_timestamp;

  new.client_updated_id = client_id;
  new.date_updated = current_timestamp;
   
  -- стартовое значение состояния документа указанное в new.kind_id
  select start_status_id, has_group
    into start_status, grp
    from kind
    where id = new.kind_id;
    
  if new.status_id is null or new.status_id != 500 or not grp then
    new.status_id = start_status;
  end if;
    
  return new;
end;
$$;


ALTER FUNCTION public.tr_doc_info_init() OWNER TO postgres;

--
-- TOC entry 261 (class 1255 OID 51962)
-- Name: tr_doc_info_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_doc_info_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  client_id uuid;
begin
  select id into client_id from client where pg_name = session_user;
  new.client_updated_id = client_id;
  new.date_updated = current_timestamp;
  return new;
end;
$$;


ALTER FUNCTION public.tr_doc_info_update() OWNER TO postgres;

--
-- TOC entry 227 (class 1255 OID 51942)
-- Name: tr_history_init(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_history_init() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.changed = current_timestamp;
  return new;
end;
$$;


ALTER FUNCTION public.tr_history_init() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 209 (class 1259 OID 52027)
-- Name: access_list; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.access_list (
    id bigint NOT NULL,
    client_id uuid NOT NULL,
    access public.access_right NOT NULL,
    value public.access_value NOT NULL,
    directory_id uuid,
    document_id uuid,
    kind_id uuid,
    changing_status_id uuid
);


ALTER TABLE public.access_list OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 52025)
-- Name: access_list_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.access_list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.access_list_id_seq OWNER TO postgres;

--
-- TOC entry 3104 (class 0 OID 0)
-- Dependencies: 208
-- Name: access_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.access_list_id_seq OWNED BY public.access_list.id;


--
-- TOC entry 215 (class 1259 OID 52180)
-- Name: addon; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.addon (
    id uuid NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    description text
);


ALTER TABLE public.addon OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 51891)
-- Name: changing_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.changing_status (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(50) NOT NULL,
    transition_id uuid NOT NULL,
    status_from_id bigint NOT NULL,
    status_to_id bigint NOT NULL,
    CONSTRAINT changing_status_eq_chk CHECK ((status_from_id <> status_to_id))
);


ALTER TABLE public.changing_status OWNER TO postgres;

--
-- TOC entry 197 (class 1259 OID 51410)
-- Name: client; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(20) NOT NULL,
    pg_name character varying(80) NOT NULL,
    surname character varying(40),
    first_name character varying(20),
    middle_name character varying(40),
    administrator boolean DEFAULT false NOT NULL,
    parent_id uuid
);


ALTER TABLE public.client OWNER TO postgres;

--
-- TOC entry 3107 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN client.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.client.name IS 'Пользователь';


--
-- TOC entry 3108 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN client.pg_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.client.pg_name IS 'Имя пользователя в Postgres';


--
-- TOC entry 3109 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN client.surname; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.client.surname IS 'Фамилия';


--
-- TOC entry 3110 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN client.first_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.client.first_name IS 'Имя';


--
-- TOC entry 3111 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN client.middle_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.client.middle_name IS 'Отчество';


--
-- TOC entry 210 (class 1259 OID 52102)
-- Name: command; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.command (
    id uuid NOT NULL,
    refresh_dataset boolean DEFAULT false NOT NULL,
    refresh_record boolean DEFAULT false NOT NULL,
    refresh_menu boolean DEFAULT false NOT NULL,
    command_type public.command_type,
    schema_data json
);


ALTER TABLE public.command OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 52118)
-- Name: constants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.constants (
    key character varying NOT NULL,
    value character varying
);


ALTER TABLE public.constants OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 53193)
-- Name: contractor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contractor (
    id uuid NOT NULL,
    short_name character varying(50) NOT NULL,
    full_name character varying(150),
    inn numeric(12,0),
    kpp numeric(9,0),
    ogrn numeric(13,0),
    okpo numeric(8,0),
    okopf_id uuid
);


ALTER TABLE public.contractor OWNER TO postgres;

--
-- TOC entry 3115 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN contractor.short_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.contractor.short_name IS 'Краткое наименование';


--
-- TOC entry 3116 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN contractor.full_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.contractor.full_name IS 'Полное наименование';


--
-- TOC entry 3117 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN contractor.inn; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.contractor.inn IS 'Индивидуальный номер налогоплателщика';


--
-- TOC entry 3118 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN contractor.kpp; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.contractor.kpp IS 'Код причины постановки на учет';


--
-- TOC entry 3119 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN contractor.ogrn; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.contractor.ogrn IS 'Основной государственный регистрационный номер';


--
-- TOC entry 3120 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN contractor.okpo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.contractor.okpo IS 'Общероссийский классификатор предприятий и организаций';


--
-- TOC entry 198 (class 1259 OID 51441)
-- Name: document_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.document_info (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    status_id bigint NOT NULL,
    owner_id uuid,
    kind_id uuid NOT NULL,
    client_created_id uuid NOT NULL,
    date_created timestamp with time zone NOT NULL,
    client_updated_id uuid NOT NULL,
    date_updated timestamp with time zone NOT NULL,
    client_locked_id uuid,
    date_locked timestamp with time zone,
    history_id bigint
);


ALTER TABLE public.document_info OWNER TO postgres;

--
-- TOC entry 3122 (class 0 OID 0)
-- Dependencies: 198
-- Name: COLUMN document_info.status_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.document_info.status_id IS 'Текущее состояние документа';


--
-- TOC entry 3123 (class 0 OID 0)
-- Dependencies: 198
-- Name: COLUMN document_info.owner_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.document_info.owner_id IS 'Владелец текущего документа';


--
-- TOC entry 3124 (class 0 OID 0)
-- Dependencies: 198
-- Name: COLUMN document_info.kind_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.document_info.kind_id IS 'Ссылка на описание свойств документа';


--
-- TOC entry 3125 (class 0 OID 0)
-- Dependencies: 198
-- Name: COLUMN document_info.client_created_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.document_info.client_created_id IS 'Пользователь создавший документ';


--
-- TOC entry 3126 (class 0 OID 0)
-- Dependencies: 198
-- Name: COLUMN document_info.date_created; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.document_info.date_created IS 'Дата создания документа';


--
-- TOC entry 3127 (class 0 OID 0)
-- Dependencies: 198
-- Name: COLUMN document_info.client_updated_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.document_info.client_updated_id IS 'Пользователь изменивший документ документ';


--
-- TOC entry 3128 (class 0 OID 0)
-- Dependencies: 198
-- Name: COLUMN document_info.date_updated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.document_info.date_updated IS 'Дата изменения документа';


--
-- TOC entry 3129 (class 0 OID 0)
-- Dependencies: 198
-- Name: COLUMN document_info.client_locked_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.document_info.client_locked_id IS 'Пользователь заблокировавший документ';


--
-- TOC entry 3130 (class 0 OID 0)
-- Dependencies: 198
-- Name: COLUMN document_info.date_locked; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.document_info.date_locked IS 'Дата блокирования документа';


--
-- TOC entry 199 (class 1259 OID 51447)
-- Name: directory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directory (
    code character varying(20) NOT NULL,
    name character varying(255),
    parent_id uuid,
    picture_id uuid
)
INHERITS (public.document_info);


ALTER TABLE public.directory OWNER TO postgres;

--
-- TOC entry 3132 (class 0 OID 0)
-- Dependencies: 199
-- Name: TABLE directory; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.directory IS 'Справочник';


--
-- TOC entry 3133 (class 0 OID 0)
-- Dependencies: 199
-- Name: COLUMN directory.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.directory.code IS 'Код записи справочника';


--
-- TOC entry 3134 (class 0 OID 0)
-- Dependencies: 199
-- Name: COLUMN directory.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.directory.name IS 'Наименование записи справочника';


--
-- TOC entry 3135 (class 0 OID 0)
-- Dependencies: 199
-- Name: COLUMN directory.parent_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.directory.parent_id IS 'Родительская запись справочника';


--
-- TOC entry 205 (class 1259 OID 51620)
-- Name: document; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.document (
    number character varying(20) NOT NULL
)
INHERITS (public.document_info);


ALTER TABLE public.document OWNER TO postgres;

--
-- TOC entry 3137 (class 0 OID 0)
-- Dependencies: 205
-- Name: COLUMN document.number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.document.number IS 'Номер документа';


--
-- TOC entry 204 (class 1259 OID 51591)
-- Name: history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.history (
    id bigint NOT NULL,
    document_id uuid,
    directory_id uuid,
    status_from_id bigint NOT NULL,
    status_to_id bigint NOT NULL,
    changed timestamp with time zone NOT NULL,
    client_id uuid NOT NULL,
    auto boolean NOT NULL,
    note character varying(255)
);


ALTER TABLE public.history OWNER TO postgres;

--
-- TOC entry 3139 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN history.client_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.history.client_id IS 'Автор перевода состояния';


--
-- TOC entry 203 (class 1259 OID 51589)
-- Name: history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.history_id_seq OWNER TO postgres;

--
-- TOC entry 3141 (class 0 OID 0)
-- Dependencies: 203
-- Name: history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.history_id_seq OWNED BY public.history.id;


--
-- TOC entry 202 (class 1259 OID 51532)
-- Name: kind; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kind (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(40),
    title character varying(255),
    is_system boolean DEFAULT false NOT NULL,
    has_group boolean DEFAULT false NOT NULL,
    type_view public.kind_type NOT NULL,
    picture_id uuid,
    transition_id uuid,
    start_status_id bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.kind OWNER TO postgres;

--
-- TOC entry 3142 (class 0 OID 0)
-- Dependencies: 202
-- Name: TABLE kind; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.kind IS 'Таблицы доступные для просмотра и редактирования';


--
-- TOC entry 3143 (class 0 OID 0)
-- Dependencies: 202
-- Name: COLUMN kind.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.kind.code IS 'Уникальный текстовый код документа';


--
-- TOC entry 3144 (class 0 OID 0)
-- Dependencies: 202
-- Name: COLUMN kind.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.kind.name IS 'Сокращенное наименование документа/справочника';


--
-- TOC entry 3145 (class 0 OID 0)
-- Dependencies: 202
-- Name: COLUMN kind.title; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.kind.title IS 'Полное наименование документа/справочника';


--
-- TOC entry 3146 (class 0 OID 0)
-- Dependencies: 202
-- Name: COLUMN kind.type_view; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.kind.type_view IS 'Вид документа';


--
-- TOC entry 3147 (class 0 OID 0)
-- Dependencies: 202
-- Name: COLUMN kind.start_status_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.kind.start_status_id IS 'Начальное состояние документа/справочника';


--
-- TOC entry 214 (class 1259 OID 52164)
-- Name: log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log (
    id bigint NOT NULL,
    client_id uuid NOT NULL,
    login_time timestamp with time zone,
    logout_time timestamp with time zone
);


ALTER TABLE public.log OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 52162)
-- Name: log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.log_id_seq OWNER TO postgres;

--
-- TOC entry 3150 (class 0 OID 0)
-- Dependencies: 213
-- Name: log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_id_seq OWNED BY public.log.id;


--
-- TOC entry 212 (class 1259 OID 52135)
-- Name: menu; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menu (
    id uuid NOT NULL,
    command_id uuid,
    order_index integer DEFAULT 0
);


ALTER TABLE public.menu OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 51489)
-- Name: picture; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.picture (
    id uuid NOT NULL,
    size16 text,
    size32 text,
    fa_name character varying(20),
    img_name character varying(255),
    note text
);


ALTER TABLE public.picture OWNER TO postgres;

--
-- TOC entry 3152 (class 0 OID 0)
-- Dependencies: 201
-- Name: COLUMN picture.fa_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.picture.fa_name IS 'Наименование иконки из Font Awesome 5';


--
-- TOC entry 200 (class 1259 OID 51484)
-- Name: status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status (
    id bigint NOT NULL,
    code character varying(80) NOT NULL,
    note character varying(255),
    picture_id uuid
);


ALTER TABLE public.status OWNER TO postgres;

--
-- TOC entry 3154 (class 0 OID 0)
-- Dependencies: 200
-- Name: TABLE status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.status IS 'Состояния документов/справочников';


--
-- TOC entry 3155 (class 0 OID 0)
-- Dependencies: 200
-- Name: COLUMN status.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.status.code IS 'Наименование состояния';


--
-- TOC entry 3156 (class 0 OID 0)
-- Dependencies: 200
-- Name: COLUMN status.note; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.status.note IS 'Полное описание состояния документа/справочника';


--
-- TOC entry 206 (class 1259 OID 51834)
-- Name: transition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transition (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.transition OWNER TO postgres;

--
-- TOC entry 2832 (class 2604 OID 52030)
-- Name: access_list id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_list ALTER COLUMN id SET DEFAULT nextval('public.access_list_id_seq'::regclass);


--
-- TOC entry 2822 (class 2604 OID 51450)
-- Name: directory id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory ALTER COLUMN id SET DEFAULT public.uuid_generate_v4();


--
-- TOC entry 2828 (class 2604 OID 51623)
-- Name: document id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document ALTER COLUMN id SET DEFAULT public.uuid_generate_v4();


--
-- TOC entry 2827 (class 2604 OID 51594)
-- Name: history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history ALTER COLUMN id SET DEFAULT nextval('public.history_id_seq'::regclass);


--
-- TOC entry 2837 (class 2604 OID 52167)
-- Name: log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log ALTER COLUMN id SET DEFAULT nextval('public.log_id_seq'::regclass);


--
-- TOC entry 3081 (class 0 OID 52027)
-- Dependencies: 209
-- Data for Name: access_list; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.access_list (id, client_id, access, value, directory_id, document_id, kind_id, changing_status_id) VALUES (2, 'beab71ba-9ccc-4966-ba61-0af178917711', 'select', 'deny', '14e90b56-62b6-45ab-a68d-cbb54afdc726', NULL, NULL, NULL);
INSERT INTO public.access_list (id, client_id, access, value, directory_id, document_id, kind_id, changing_status_id) VALUES (4, 'beab71ba-9ccc-4966-ba61-0af178917711', 'execute', 'deny', 'c033de00-4d05-4e28-9e99-43ab8b1af758', NULL, NULL, NULL);


--
-- TOC entry 3087 (class 0 OID 52180)
-- Dependencies: 215
-- Data for Name: addon; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.addon (id, version, description) VALUES ('7d2e10bd-c0eb-4926-8018-d13127950b3f', 1, 'Контрагенты');


--
-- TOC entry 3079 (class 0 OID 51891)
-- Dependencies: 207
-- Data for Name: changing_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.changing_status (id, name, transition_id, status_from_id, status_to_id) VALUES ('7e6bfac8-6920-4e01-b5b0-61ee39114814', 'Проверен', '0a27ee87-8fa1-49bd-a76c-0014081dfdec', 1000, 1001);
INSERT INTO public.changing_status (id, name, transition_id, status_from_id, status_to_id) VALUES ('d78ec4a2-949b-466e-a0a9-838368a3a5f3', 'Изменяется', '0a27ee87-8fa1-49bd-a76c-0014081dfdec', 1001, 1000);
INSERT INTO public.changing_status (id, name, transition_id, status_from_id, status_to_id) VALUES ('b374e0fa-f62d-477c-8fd2-fc8d9d1782eb', 'Проверен', '5099ac3d-81d3-4e83-a2e6-5d0dab48dbde', 1000, 1001);
INSERT INTO public.changing_status (id, name, transition_id, status_from_id, status_to_id) VALUES ('782059e7-cda6-4ded-b609-facd68c5d0fd', 'Утвержден', '5099ac3d-81d3-4e83-a2e6-5d0dab48dbde', 1001, 1002);
INSERT INTO public.changing_status (id, name, transition_id, status_from_id, status_to_id) VALUES ('e05611aa-6b30-4410-8ca6-52c5f5834459', 'Изменяется', '5099ac3d-81d3-4e83-a2e6-5d0dab48dbde', 1001, 1004);
INSERT INTO public.changing_status (id, name, transition_id, status_from_id, status_to_id) VALUES ('178b475c-1be8-48d8-8050-725ce500f092', 'Отменен', '5099ac3d-81d3-4e83-a2e6-5d0dab48dbde', 1002, 1003);
INSERT INTO public.changing_status (id, name, transition_id, status_from_id, status_to_id) VALUES ('5650ee8e-f5cf-4b52-b19f-dbcefcae6f06', 'Изменяется', '5099ac3d-81d3-4e83-a2e6-5d0dab48dbde', 1002, 1004);
INSERT INTO public.changing_status (id, name, transition_id, status_from_id, status_to_id) VALUES ('351884ef-f5df-4da1-82db-2cd3309b7db7', 'Новая редакция', '5099ac3d-81d3-4e83-a2e6-5d0dab48dbde', 1004, 1001);
INSERT INTO public.changing_status (id, name, transition_id, status_from_id, status_to_id) VALUES ('277f367f-6d3f-4582-87bc-c8543cb80756', 'Установка', 'dafae4fd-8139-4b43-b6b9-9120500730dc', 1005, 1006);
INSERT INTO public.changing_status (id, name, transition_id, status_from_id, status_to_id) VALUES ('ab759eed-08f4-4a0a-9ec2-f1d87ba7f07a', 'Удаление', 'dafae4fd-8139-4b43-b6b9-9120500730dc', 1006, 1005);


--
-- TOC entry 3069 (class 0 OID 51410)
-- Dependencies: 197
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.client (id, name, pg_name, surname, first_name, middle_name, administrator, parent_id) VALUES ('936068c8-8f15-403e-a1b6-5407f1ab286b', 'Создатель', 'postgres', NULL, NULL, NULL, true, NULL);
INSERT INTO public.client (id, name, pg_name, surname, first_name, middle_name, administrator, parent_id) VALUES ('193d4780-81dd-4f44-83ea-d19523b4a3c2', 'Гость', 'guest', NULL, NULL, NULL, false, NULL);
INSERT INTO public.client (id, name, pg_name, surname, first_name, middle_name, administrator, parent_id) VALUES ('beab71ba-9ccc-4966-ba61-0af178917711', 'Пользователи', 'users', NULL, NULL, NULL, false, NULL);
INSERT INTO public.client (id, name, pg_name, surname, first_name, middle_name, administrator, parent_id) VALUES ('76a1de06-0a74-41e9-8c38-8e3d7f90c855', 'Администраторы', 'admins', NULL, NULL, NULL, false, NULL);
INSERT INTO public.client (id, name, pg_name, surname, first_name, middle_name, administrator, parent_id) VALUES ('b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', 'Администратор', 'admin', NULL, NULL, NULL, true, '76a1de06-0a74-41e9-8c38-8e3d7f90c855');
INSERT INTO public.client (id, name, pg_name, surname, first_name, middle_name, administrator, parent_id) VALUES ('853337fd-b927-4d6f-99af-a8335bcf7a94', 'Сергей', 'sergio', 'Тепляшин', 'Сергей', 'Васильевич', false, 'beab71ba-9ccc-4966-ba61-0af178917711');


--
-- TOC entry 3082 (class 0 OID 52102)
-- Dependencies: 210
-- Data for Name: command; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.command (id, refresh_dataset, refresh_record, refresh_menu, command_type, schema_data) VALUES ('b72e25ba-8a8d-4d8b-9995-bdd7d2ade55a', false, false, false, NULL, NULL);
INSERT INTO public.command (id, refresh_dataset, refresh_record, refresh_menu, command_type, schema_data) VALUES ('c8f732b9-40e5-436e-82b4-1e08d86ee18c', false, false, false, NULL, NULL);
INSERT INTO public.command (id, refresh_dataset, refresh_record, refresh_menu, command_type, schema_data) VALUES ('cde886b5-1cca-4759-9ec8-84b80e2fa050', false, false, false, NULL, NULL);
INSERT INTO public.command (id, refresh_dataset, refresh_record, refresh_menu, command_type, schema_data) VALUES ('b90d587f-8352-4f94-bdb1-54526c906943', false, false, false, 'view_table', '{
	  "viewer": {
    	"master": "addon",
	    "datasets": [
    	  {
        	"name": "addon",
	        "select": "select * from addon_select()",
    	    "columns": [
    	      {
				"datafield": "status_picture_id",
				"text": "",
				"type": "image",
				"width": 30,
				"hideable": false,
				"hidden": false,
				"sortable": false,
				"resizable": false
              },
        	  {
            	"datafield": "id",
	            "text": "Id",
    	        "type": "text",
        	    "width": 180,
            	"hideable": true,
	            "hidden": true,
    	        "sortable": false
        	  },
        	  {
				"datafield": "status_id",
				"text": "Код состояния",
				"type": "integer",
				"width": 80,
				"hideable": true,
				"hidden": true,
				"sortable": true
              },
    	      {
        	    "datafield": "status_name",
            	"text": "Состояние",
	            "type": "text",
    	        "width": 110,
        	    "hideable": true,
            	"hidden": true,
	            "sortable": true
    	      },
        	  {
            	"datafield": "code",
	            "text": "Код",
    	        "type": "text",
        	    "width": 90,
            	"hideable": true,
	            "hidden": true,
    	        "sortable": true
        	  },
	          {
    	        "datafield": "name",
        	    "text": "Наименование",
            	"type": "text",
	            "width": "auto",
    	        "hideable": false,
        	    "hidden": false,
            	"sortable": true
	          },
	          {
    	        "datafield": "version",
        	    "text": "Версия",
            	"type": "integer",
	            "width": "80",
    	        "hideable": true,
        	    "hidden": false,
            	"sortable": true
	          },
	          {
    	        "datafield": "description",
        	    "text": "Описание",
            	"type": "memo",
	            "width": "100",
    	        "hideable": true,
        	    "hidden": true,
            	"sortable": false
	          }
    	    ]
	      }
	    ]
	  }
	}');
INSERT INTO public.command (id, refresh_dataset, refresh_record, refresh_menu, command_type, schema_data) VALUES ('09c7a774-efae-4dd0-910a-119202aae662', false, false, false, 'view_table', NULL);
INSERT INTO public.command (id, refresh_dataset, refresh_record, refresh_menu, command_type, schema_data) VALUES ('c033de00-4d05-4e28-9e99-43ab8b1af758', false, false, false, 'edit_record', NULL);
INSERT INTO public.command (id, refresh_dataset, refresh_record, refresh_menu, command_type, schema_data) VALUES ('104e148e-8adb-4836-9fd1-3ed5206dcdf5', false, false, false, 'view_table', '{
	  "viewer": {
    	"master": "okopf",
	    "datasets": [
    	  {
        	"name": "okopf",
	        "select": "select * from okopf_select()",
    	    "columns": [
    	      {
				"datafield": "status_picture_id",
				"text": "",
				"type": "image",
				"width": 30,
				"hideable": false,
				"hidden": false,
				"sortable": false,
				"resizable": false
              }, 
        	  {
            	"datafield": "id",
	            "text": "Id",
    	        "type": "text",
        	    "width": 180,
            	"hideable": true,
	            "hidden": true,
    	        "sortable": false
        	  },
        	  {
				"datafield": "status_id",
				"text": "Код состояния",
				"type": "integer",
				"width": 80,
				"hideable": true,
				"hidden": true,
				"sortable": true
              },
    	      {
        	    "datafield": "status_name",
            	"text": "Состояние",
	            "type": "text",
    	        "width": 110,
        	    "hideable": true,
            	"hidden": true,
	            "sortable": true
    	      },
        	  {
            	"datafield": "code",
	            "text": "Код",
    	        "type": "text",
        	    "width": 90,
            	"hideable": true,
	            "hidden": false,
    	        "sortable": true
        	  },
	          {
    	        "datafield": "name",
        	    "text": "Наименование",
            	"type": "text",
	            "width": "auto",
    	        "hideable": false,
        	    "hidden": false,
            	"sortable": true
	          }
    	    ]
	      }
	    ]
	  }
	}');
INSERT INTO public.command (id, refresh_dataset, refresh_record, refresh_menu, command_type, schema_data) VALUES ('e8a8f0ad-2528-4db1-8726-d128b82bf12b', false, false, false, 'view_table', '{
	"viewer": {
		"master": "contractor",
		"datasets": [{
				"name": "contractor",
				"select": "select * from contractor_select(:id, :parent)",
				"columns": [{
						"datafield": "status_picture_id",
						"text": "",
						"type": "image",
						"width": 30,
						"hideable": false,
						"hidden": false,
						"sortable": false,
						"resizable": false
					}, {
						"datafield": "id",
						"text": "Id",
						"type": "text",
						"width": 180,
						"hideable": true,
						"hidden": true,
						"sortable": false
					}, {
						"datafield": "status_id",
						"text": "Код состояния",
						"type": "integer",
						"width": 80,
						"hideable": true,
						"hidden": true,
						"sortable": true
					}, {
						"datafield": "status_name",
						"text": "Состояние",
						"type": "text",
						"width": 110,
						"hideable": true,
						"hidden": true,
						"sortable": true
					}, {
						"datafield": "code",
						"text": "Код",
						"type": "text",
						"width": 90,
						"hideable": true,
						"hidden": true,
						"sortable": true
					}, {
						"datafield": "name",
						"text": "Наименование",
						"type": "text",
						"width": "auto",
						"hideable": false,
						"hidden": false,
						"sortable": true
					}, {
						"datafield": "short_name",
						"text": "Краткое наименование",
						"type": "text",
						"width": 400,
						"hideable": true,
						"hidden": false,
						"sortable": true
					}, {
						"datafield": "full_name",
						"text": "Полное наименование",
						"type": "text",
						"width": 150,
						"hideable": true,
						"hidden": true,
						"sortable": true
					}, {
						"datafield": "inn",
						"text": "ИНН",
						"type": "integer",
						"width": 100,
						"hideable": true,
						"hidden": false,
						"sortable": true
					}, {
						"datafield": "kpp",
						"text": "КПП",
						"type": "integer",
						"width": 100,
						"hideable": true,
						"hidden": true,
						"sortable": true
					}, {
						"datafield": "okpo",
						"text": "ОКПО",
						"type": "integer",
						"width": 100,
						"hideable": true,
						"hidden": true,
						"sortable": true
					}, {
						"datafield": "ogrn",
						"text": "ОГРН",
						"type": "integer",
						"width": 120,
						"hideable": true,
						"hidden": true,
						"sortable": true
					}, {
						"datafield": "okopf_name",
						"text": "ОКОПФ",
						"type": "text",
						"width": 170,
						"hideable": true,
						"hidden": true,
						"sortable": true
					}
				]
			}
		]
	}
}
');


--
-- TOC entry 3083 (class 0 OID 52118)
-- Dependencies: 211
-- Data for Name: constants; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.constants (key, value) VALUES ('kind.command', '1cbd0fa1-f70c-4915-b31e-eb35194ff8f3');
INSERT INTO public.constants (key, value) VALUES ('kind.picture', '331e138d-d586-44ad-aae5-a922df10d0c2');
INSERT INTO public.constants (key, value) VALUES ('kind.menu', 'f5e583f6-09b8-4d22-aa86-7b45b794d3ba');
INSERT INTO public.constants (key, value) VALUES ('kind.okopf', '6544b97c-a78c-4a62-840f-d2c809c977bc');
INSERT INTO public.constants (key, value) VALUES ('kind.contractor', '2583b9e1-6500-4b22-993b-556d912c1726');
INSERT INTO public.constants (key, value) VALUES ('kind.addon', '21492b7b-aa7d-4431-9ef0-c79099b9b36e');
INSERT INTO public.constants (key, value) VALUES ('picture.status', '8d491ef2-a8de-418b-8b88-64238e550663');


--
-- TOC entry 3088 (class 0 OID 53193)
-- Dependencies: 216
-- Data for Name: contractor; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.contractor (id, short_name, full_name, inn, kpp, ogrn, okpo, okopf_id) VALUES ('b8ccefca-769e-48d3-98f9-5bf6c9f5562a', 'ООО "Димитровград ЖгутКомплект"', 'Общество с ограниченной ответственностью "Димитровград ЖгутКомплект"', 7302004942, 730201001, 1027300537593, 25233081, 'f60cf726-1227-4c09-9974-cc8fbc275b0c');
INSERT INTO public.contractor (id, short_name, full_name, inn, kpp, ogrn, okpo, okopf_id) VALUES ('9d66309f-d935-45f4-a8ef-431185ed7b3f', 'АО "Завод "Копир"', NULL, 1217000287, 121701001, 1021202049637, 7585144, 'fd5a72c4-1505-42aa-8010-46f4600ccb68');
INSERT INTO public.contractor (id, short_name, full_name, inn, kpp, ogrn, okpo, okopf_id) VALUES ('949fa8c4-3d66-4103-9188-aca701d671b0', 'АО "Марпосадкабель"', NULL, 2111006918, 211101001, 1042135001600, 71025920, 'fd5a72c4-1505-42aa-8010-46f4600ccb68');
INSERT INTO public.contractor (id, short_name, full_name, inn, kpp, ogrn, okpo, okopf_id) VALUES ('5597b68a-c33e-4097-a0e1-f3945ad67ddf', 'АО "Региональный Сетевой Информа', NULL, 7733573894, 773401001, 1067746823099, 96482133, 'fd5a72c4-1505-42aa-8010-46f4600ccb68');
INSERT INTO public.contractor (id, short_name, full_name, inn, kpp, ogrn, okpo, okopf_id) VALUES ('853f55ac-106b-4ec4-aecd-d9dbcda1d65c', 'ООО "Димитровградский завод стеклоподъемников"', NULL, 7302019473, 730201001, 1027300540937, 25387508, 'f60cf726-1227-4c09-9974-cc8fbc275b0c');
INSERT INTO public.contractor (id, short_name, full_name, inn, kpp, ogrn, okpo, okopf_id) VALUES ('e9201ef5-da20-4a8f-980a-3a3b5636643d', 'ООО "Промдом"', NULL, 7329014105, 732901002, 1147329001050, 25222060, 'f60cf726-1227-4c09-9974-cc8fbc275b0c');
INSERT INTO public.contractor (id, short_name, full_name, inn, kpp, ogrn, okpo, okopf_id) VALUES ('b8961cae-f03e-4448-bb1b-14b0a7eda338', 'ООО "ТПЦ"', NULL, 7302028654, 730201001, 1047300107359, 25477223, 'f60cf726-1227-4c09-9974-cc8fbc275b0c');


--
-- TOC entry 3071 (class 0 OID 51447)
-- Dependencies: 199
-- Data for Name: directory; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('63aba729-5361-4b0c-80cc-1767b31af1a3', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:31:55.1026+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:32:04.466163+04', NULL, NULL, 'compiled', 'Составлен', '8d491ef2-a8de-418b-8b88-64238e550663', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('b18abc1d-8c6b-4117-8573-730f615a44bb', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:33:20.088885+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:33:25.482094+04', NULL, NULL, 'correct', 'Корректен', '8d491ef2-a8de-418b-8b88-64238e550663', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('3d947b1e-af43-438c-bdbd-ccab6d6020c6', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:34:10.492302+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:34:16.363464+04', NULL, NULL, 'expired', 'Утратил силу', '8d491ef2-a8de-418b-8b88-64238e550663', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('9a29b793-a2e0-42b2-bf87-a5904faddf2e', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:34:57.84557+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:35:02.365031+04', NULL, NULL, 'approved by', 'Утвержден', '8d491ef2-a8de-418b-8b88-64238e550663', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('ad3f724f-6759-40f1-a69e-ca04137f4aa9', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:35:39.838806+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:35:43.998062+04', NULL, NULL, 'is changing', 'Изменяется', '8d491ef2-a8de-418b-8b88-64238e550663', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('09c7a774-efae-4dd0-910a-119202aae662', 0, NULL, '1cbd0fa1-f70c-4915-b31e-eb35194ff8f3', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:48:30.368734+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:35:31.27609+04', NULL, NULL, 'cmd-view-users', 'Список пользователей', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('7d2e10bd-c0eb-4926-8018-d13127950b3f', 1006, NULL, '21492b7b-aa7d-4431-9ef0-c79099b9b36e', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 17:35:00.47886+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 16:28:37.832778+04', NULL, NULL, 'addon-contractor', 'Контрагенты', NULL, NULL, 1);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('9d66309f-d935-45f4-a8ef-431185ed7b3f', 1000, NULL, '2583b9e1-6500-4b22-993b-556d912c1726', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-11 11:08:03.348396+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-11 11:08:03.348396+04', NULL, NULL, 'Завод Копир', 'Завод Копир', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('32a8d594-ac1c-49b3-a89b-e79080452942', 500, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 19:26:54.681657+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 16:29:28.340273+04', NULL, NULL, 'objects', 'Объекты', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('c8f732b9-40e5-436e-82b4-1e08d86ee18c', 500, NULL, '1cbd0fa1-f70c-4915-b31e-eb35194ff8f3', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-29 21:30:34.12958+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 16:29:30.781656+04', NULL, NULL, 'cmd-fld-exec-proc', 'Выполнение процедуры', 'b72e25ba-8a8d-4d8b-9995-bdd7d2ade55a', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('cde886b5-1cca-4759-9ec8-84b80e2fa050', 500, NULL, '1cbd0fa1-f70c-4915-b31e-eb35194ff8f3', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-29 21:29:57.196326+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 16:29:32.693885+04', NULL, NULL, 'cmd-fld-view-dict', 'Просмотр справочника', 'b72e25ba-8a8d-4d8b-9995-bdd7d2ade55a', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('b72e25ba-8a8d-4d8b-9995-bdd7d2ade55a', 500, NULL, '1cbd0fa1-f70c-4915-b31e-eb35194ff8f3', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-29 21:28:54.00761+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 16:29:34.503948+04', NULL, NULL, 'cmd-fld-directorry', 'Команды справочников', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('853f55ac-106b-4ec4-aecd-d9dbcda1d65c', 1000, NULL, '2583b9e1-6500-4b22-993b-556d912c1726', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:22:06.700813+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:22:06.700813+04', NULL, NULL, 'ДЗСтп', 'ДЗСтп', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('14e90b56-62b6-45ab-a68d-cbb54afdc726', 500, NULL, 'f5e583f6-09b8-4d22-aa86-7b45b794d3ba', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-29 22:23:02.409123+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 16:29:36.417182+04', NULL, NULL, 'menu-system', 'Система', NULL, '4fa5d174-ecee-4634-9973-6d4be41413f1', NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('243e71b9-1c3c-4a37-a81a-9bc4e316f986', 500, NULL, 'f5e583f6-09b8-4d22-aa86-7b45b794d3ba', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:24:29.223541+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 16:29:38.435912+04', NULL, NULL, 'menu-documents', 'Документы', NULL, 'ad84a7b0-cd67-4f46-bdb8-f9ec6b4c7a25', NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('104e148e-8adb-4836-9fd1-3ed5206dcdf5', 0, NULL, '1cbd0fa1-f70c-4915-b31e-eb35194ff8f3', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-29 22:35:53.409177+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:23:33.709138+04', NULL, NULL, 'cmd-view-okopf', 'ОКОПФ', 'cde886b5-1cca-4759-9ec8-84b80e2fa050', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('8d491ef2-a8de-418b-8b88-64238e550663', 500, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-28 22:19:52.424682+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 16:29:40.489425+04', NULL, NULL, 'state', 'Состояния документов', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('2884186c-a011-4e11-8f32-474bf29816bd', 0, NULL, 'f5e583f6-09b8-4d22-aa86-7b45b794d3ba', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 00:04:49.118567+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:23:33.709138+04', NULL, NULL, 'menu-okopf', 'ОКОПФ', '6f3041cc-7eeb-4a68-82cc-6e977d632fbf', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('dbc0b7fb-7bb3-4214-b87c-1e3d2157c2dd', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 21:38:08.663694+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 21:38:26.239524+04', NULL, NULL, 'installed', 'Установлено', '8d491ef2-a8de-418b-8b88-64238e550663', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('df3a2195-d3ad-4779-b865-051159c27454', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 21:38:51.183776+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 21:38:54.12656+04', NULL, NULL, 'not installed', 'Не установлено', '8d491ef2-a8de-418b-8b88-64238e550663', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('00e5691b-1e20-4f15-991a-aaf896bcded8', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 21:42:30.630299+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 21:42:35.123229+04', NULL, NULL, 'unknown', 'Не известно', '8d491ef2-a8de-418b-8b88-64238e550663', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('6f3041cc-7eeb-4a68-82cc-6e977d632fbf', 500, NULL, 'f5e583f6-09b8-4d22-aa86-7b45b794d3ba', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-29 22:24:20.475338+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 16:29:42.503547+04', NULL, NULL, 'menu-directories', 'Справочники', NULL, 'fd7628f8-a276-4d4a-bc54-8b6363902919', NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('b90d587f-8352-4f94-bdb1-54526c906943', 0, NULL, '1cbd0fa1-f70c-4915-b31e-eb35194ff8f3', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 21:52:15.065874+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:36:03.096414+04', NULL, NULL, 'cmd-view-addon', 'Дополнения', 'cde886b5-1cca-4759-9ec8-84b80e2fa050', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('b81c1b03-21f5-4664-8328-06457a7935bc', 0, NULL, 'f5e583f6-09b8-4d22-aa86-7b45b794d3ba', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-29 22:23:35.409735+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:37:29.980177+04', NULL, NULL, 'menu-addon', 'Дополнения', '14e90b56-62b6-45ab-a68d-cbb54afdc726', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('c033de00-4d05-4e28-9e99-43ab8b1af758', 0, NULL, '1cbd0fa1-f70c-4915-b31e-eb35194ff8f3', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:48:43.728993+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:36:15.921444+04', NULL, NULL, 'cmd-profile', 'Профиль', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('fd7628f8-a276-4d4a-bc54-8b6363902919', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 19:28:37.811933+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:23:03.20478+04', NULL, NULL, 'book', 'Справочники', '32a8d594-ac1c-49b3-a89b-e79080452942', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('4fa5d174-ecee-4634-9973-6d4be41413f1', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 19:29:19.311826+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:23:08.310996+04', NULL, NULL, 'cogs', 'Система', '32a8d594-ac1c-49b3-a89b-e79080452942', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('ad84a7b0-cd67-4f46-bdb8-f9ec6b4c7a25', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:22:27.878837+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:23:12.171068+04', NULL, NULL, 'file-alt', 'Документы', '32a8d594-ac1c-49b3-a89b-e79080452942', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('ba9f4e27-8458-4416-be25-de1f709d756d', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:30:37.207588+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:30:46.544047+04', NULL, NULL, 'wrench', 'Настройки', '32a8d594-ac1c-49b3-a89b-e79080452942', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('9ff4c34c-76f3-4658-b209-e5ccc5aea521', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:36:45.864401+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:36:53.498928+04', NULL, NULL, 'users', 'Пользователи', '32a8d594-ac1c-49b3-a89b-e79080452942', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('7d656422-6b5b-46d8-a520-50c6b0d6a430', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:37:55.482718+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:38:00.287319+04', NULL, NULL, 'user-circle', 'Профиль', '32a8d594-ac1c-49b3-a89b-e79080452942', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('569e2010-9d89-4200-9ab6-228738ad6a67', 0, NULL, 'f5e583f6-09b8-4d22-aa86-7b45b794d3ba', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:39:22.687556+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:36:47.949264+04', NULL, NULL, 'menu-users', 'Пользователи', NULL, '9ff4c34c-76f3-4658-b209-e5ccc5aea521', NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('233f7159-ce32-4eb9-b88c-f08f688b342e', 1000, NULL, '6544b97c-a78c-4a62-840f-d2c809c977bc', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-27 17:21:08.40782+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:23:33.709138+04', NULL, NULL, '50102', 'Индивидуальные предприниматели', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('f60cf726-1227-4c09-9974-cc8fbc275b0c', 1000, NULL, '6544b97c-a78c-4a62-840f-d2c809c977bc', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-27 17:20:37.758274+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:23:33.709138+04', NULL, NULL, '12300', 'Общества с ограниченной ответственностью', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('e8a8f0ad-2528-4db1-8726-d128b82bf12b', 0, NULL, '1cbd0fa1-f70c-4915-b31e-eb35194ff8f3', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 17:35:00.47886+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:23:33.709138+04', NULL, NULL, 'cmd-view-contractor', 'Контрагенты', 'cde886b5-1cca-4759-9ec8-84b80e2fa050', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('9bf6884b-ab40-444d-a29b-c8e5fbfc4957', 0, NULL, 'f5e583f6-09b8-4d22-aa86-7b45b794d3ba', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 17:35:00.47886+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:23:33.709138+04', NULL, NULL, 'menu-contractor', 'Контрагенты', '6f3041cc-7eeb-4a68-82cc-6e977d632fbf', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('ae8a4648-7e8f-47f1-8f10-503bcba7008d', 0, NULL, 'f5e583f6-09b8-4d22-aa86-7b45b794d3ba', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:40:01.994407+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:37:16.456605+04', NULL, NULL, 'menu-profile', 'Профиль', NULL, '7d656422-6b5b-46d8-a520-50c6b0d6a430', NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('ec5fa0c1-71fe-4553-b920-ab627e4cef73', 0, NULL, 'f5e583f6-09b8-4d22-aa86-7b45b794d3ba', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-26 21:27:32.704773+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-03 21:37:27.186083+04', NULL, NULL, 'menu-settings', 'Настройки', '14e90b56-62b6-45ab-a68d-cbb54afdc726', NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('949fa8c4-3d66-4103-9188-aca701d671b0', 1000, NULL, '2583b9e1-6500-4b22-993b-556d912c1726', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:23:19.616862+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:23:19.616862+04', NULL, NULL, 'Марпосадкабель', 'Марпосадкабель', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('b8ccefca-769e-48d3-98f9-5bf6c9f5562a', 1000, NULL, '2583b9e1-6500-4b22-993b-556d912c1726', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:27:51.413756+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:27:51.413756+04', NULL, NULL, 'ДЖК', 'ДЖК', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('b8961cae-f03e-4448-bb1b-14b0a7eda338', 1000, NULL, '2583b9e1-6500-4b22-993b-556d912c1726', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:28:29.452149+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:28:29.452149+04', NULL, NULL, 'ТПЦ', 'ТПЦ', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('e9201ef5-da20-4a8f-980a-3a3b5636643d', 1000, NULL, '2583b9e1-6500-4b22-993b-556d912c1726', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:29:22.088291+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:29:22.088291+04', NULL, NULL, 'Промдом', 'Промдом', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('fd5a72c4-1505-42aa-8010-46f4600ccb68', 1000, NULL, '6544b97c-a78c-4a62-840f-d2c809c977bc', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:39:56.033716+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:39:56.033716+04', NULL, NULL, '12267', 'Непубличные акционерные общества', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('5597b68a-c33e-4097-a0e1-f3945ad67ddf', 1000, NULL, '2583b9e1-6500-4b22-993b-556d912c1726', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:34:28.965402+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-13 20:41:15.156768+04', NULL, NULL, 'РСИЦ', 'Региональный Сетевой Инф. Цент', NULL, NULL, NULL);
INSERT INTO public.directory (id, status_id, owner_id, kind_id, client_created_id, date_created, client_updated_id, date_updated, client_locked_id, date_locked, code, name, parent_id, picture_id, history_id) VALUES ('0a6136b7-8739-48ed-8673-f78a4be35a8c', 0, NULL, '331e138d-d586-44ad-aae5-a922df10d0c2', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 10:32:19.167252+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-02 10:32:19.167252+04', NULL, NULL, 'folder', 'Папка', '8d491ef2-a8de-418b-8b88-64238e550663', NULL, NULL);


--
-- TOC entry 3077 (class 0 OID 51620)
-- Dependencies: 205
-- Data for Name: document; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3070 (class 0 OID 51441)
-- Dependencies: 198
-- Data for Name: document_info; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3076 (class 0 OID 51591)
-- Dependencies: 204
-- Data for Name: history; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.history (id, document_id, directory_id, status_from_id, status_to_id, changed, client_id, auto, note) VALUES (1, NULL, '7d2e10bd-c0eb-4926-8018-d13127950b3f', 1005, 1006, '2018-11-03 17:35:00.47886+04', '936068c8-8f15-403e-a1b6-5407f1ab286b', false, NULL);


--
-- TOC entry 3074 (class 0 OID 51532)
-- Dependencies: 202
-- Data for Name: kind; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.kind (id, code, name, title, is_system, has_group, type_view, picture_id, transition_id, start_status_id) VALUES ('331e138d-d586-44ad-aae5-a922df10d0c2', 'picture', 'Изображение', 'Изображение', true, true, 'directory', NULL, '75d6daef-1269-4aa9-af79-48e17f4389da', 0);
INSERT INTO public.kind (id, code, name, title, is_system, has_group, type_view, picture_id, transition_id, start_status_id) VALUES ('1cbd0fa1-f70c-4915-b31e-eb35194ff8f3', 'command', 'Команда', 'Команда', true, true, 'directory', NULL, '75d6daef-1269-4aa9-af79-48e17f4389da', 0);
INSERT INTO public.kind (id, code, name, title, is_system, has_group, type_view, picture_id, transition_id, start_status_id) VALUES ('f5e583f6-09b8-4d22-aa86-7b45b794d3ba', 'menu', 'Меню', 'Меню', true, true, 'directory', NULL, '75d6daef-1269-4aa9-af79-48e17f4389da', 0);
INSERT INTO public.kind (id, code, name, title, is_system, has_group, type_view, picture_id, transition_id, start_status_id) VALUES ('21492b7b-aa7d-4431-9ef0-c79099b9b36e', 'addon', 'Дополнение', 'Дополнение', true, false, 'directory', NULL, 'dafae4fd-8139-4b43-b6b9-9120500730dc', 1005);
INSERT INTO public.kind (id, code, name, title, is_system, has_group, type_view, picture_id, transition_id, start_status_id) VALUES ('6544b97c-a78c-4a62-840f-d2c809c977bc', 'okopf', 'ОКОПФ', 'Общероссийский классификатор организационно-правовых форм', false, false, 'directory', NULL, '0a27ee87-8fa1-49bd-a76c-0014081dfdec', 1000);
INSERT INTO public.kind (id, code, name, title, is_system, has_group, type_view, picture_id, transition_id, start_status_id) VALUES ('2583b9e1-6500-4b22-993b-556d912c1726', 'contractor', 'Контрагенты', 'Контрагенты', false, true, 'directory', NULL, '5099ac3d-81d3-4e83-a2e6-5d0dab48dbde', 1000);


--
-- TOC entry 3086 (class 0 OID 52164)
-- Dependencies: 214
-- Data for Name: log; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (1, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 20:22:12.053593+04', '2018-09-30 20:23:29.536381+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (2, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 20:23:29.536381+04', '2018-09-30 20:25:52.207927+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (3, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 20:25:52.207927+04', '2018-09-30 20:28:19.577504+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (4, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 20:28:19.577504+04', '2018-09-30 20:29:12.478778+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (5, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 20:29:12.478778+04', '2018-09-30 20:33:09.085663+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (6, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 20:33:09.085663+04', '2018-09-30 20:41:34.073721+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (7, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-09-30 20:41:34.073721+04', '2018-09-30 20:46:23.72658+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (10, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-09-30 20:50:48.993601+04', '2018-10-03 21:20:04.054917+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (11, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-03 21:20:04.054917+04', '2018-10-07 15:51:39.028901+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (8, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-09-30 20:46:23.72658+04', '2018-10-20 22:45:23.957643+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (13, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-10-20 22:45:23.957643+04', '2018-10-20 23:02:58.032072+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (14, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-10-20 23:02:58.032072+04', '2018-10-24 18:46:36.908077+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (12, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-07 15:51:39.028901+04', '2018-10-25 20:23:38.575653+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (9, 'b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', '2018-09-30 20:47:02.634712+04', '2018-10-25 23:09:26.537558+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (17, 'b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', '2018-10-25 23:09:26.537558+04', '2018-10-26 20:27:31.952144+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (15, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-10-24 18:46:36.908077+04', '2018-10-26 20:27:43.848598+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (18, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-10-26 20:27:43.848598+04', '2018-10-26 20:27:48.54788+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (19, 'b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', '2018-10-26 21:16:26.861287+04', '2018-10-26 22:09:01.235888+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (20, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-10-26 22:09:10.402454+04', '2018-10-26 22:09:30.393857+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (21, 'b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', '2018-10-27 16:00:58.794077+04', '2018-10-28 23:36:08.822186+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (22, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-10-27 21:00:51.301822+04', '2018-10-28 23:36:17.057624+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (23, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-10-28 23:36:17.057624+04', '2018-11-03 08:40:30.610892+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (24, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-11-03 08:40:30.610892+04', '2018-11-03 16:45:16.17427+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (16, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-10-25 20:23:38.575653+04', '2018-11-14 22:38:02.259461+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (25, 'b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', '2018-11-03 17:35:23.192082+04', '2018-11-18 10:26:05.018334+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (27, 'b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', '2018-11-18 10:26:46.46659+04', '2018-11-18 11:49:34.505186+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (26, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-14 22:38:02.259461+04', '2018-11-18 12:27:42.236145+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (29, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-18 12:27:42.236145+04', '2018-11-18 12:31:16.774094+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (30, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-18 12:31:16.774094+04', '2018-11-18 12:35:07.017764+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (28, 'b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', '2018-11-18 11:49:34.505186+04', '2018-11-20 22:50:12.156432+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (32, '853337fd-b927-4d6f-99af-a8335bcf7a94', '2018-11-20 22:50:18.911978+04', '2018-11-20 22:50:31.862813+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (33, 'b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', '2018-11-20 22:52:02.849446+04', '2018-12-02 22:54:04.759382+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (34, 'b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', '2018-12-02 22:55:25.28122+04', '2018-12-13 21:32:44.86173+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (35, 'b02b7fb3-8198-4710-b9ce-cb9e869cfe1b', '2018-12-13 21:34:13.795115+04', NULL);
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (31, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-11-18 12:35:07.017764+04', '2018-12-14 18:29:29.908925+04');
INSERT INTO public.log (id, client_id, login_time, logout_time) VALUES (36, '936068c8-8f15-403e-a1b6-5407f1ab286b', '2018-12-14 18:29:29.908925+04', NULL);


--
-- TOC entry 3084 (class 0 OID 52135)
-- Dependencies: 212
-- Data for Name: menu; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.menu (id, command_id, order_index) VALUES ('b81c1b03-21f5-4664-8328-06457a7935bc', 'b90d587f-8352-4f94-bdb1-54526c906943', 0);
INSERT INTO public.menu (id, command_id, order_index) VALUES ('ec5fa0c1-71fe-4553-b920-ab627e4cef73', NULL, 0);
INSERT INTO public.menu (id, command_id, order_index) VALUES ('243e71b9-1c3c-4a37-a81a-9bc4e316f986', NULL, 10);
INSERT INTO public.menu (id, command_id, order_index) VALUES ('6f3041cc-7eeb-4a68-82cc-6e977d632fbf', NULL, 20);
INSERT INTO public.menu (id, command_id, order_index) VALUES ('14e90b56-62b6-45ab-a68d-cbb54afdc726', NULL, 30);
INSERT INTO public.menu (id, command_id, order_index) VALUES ('569e2010-9d89-4200-9ab6-228738ad6a67', '09c7a774-efae-4dd0-910a-119202aae662', 40);
INSERT INTO public.menu (id, command_id, order_index) VALUES ('ae8a4648-7e8f-47f1-8f10-503bcba7008d', 'c033de00-4d05-4e28-9e99-43ab8b1af758', 50);
INSERT INTO public.menu (id, command_id, order_index) VALUES ('2884186c-a011-4e11-8f32-474bf29816bd', '104e148e-8adb-4836-9fd1-3ed5206dcdf5', 0);
INSERT INTO public.menu (id, command_id, order_index) VALUES ('9bf6884b-ab40-444d-a29b-c8e5fbfc4957', 'e8a8f0ad-2528-4db1-8726-d128b82bf12b', 0);


--
-- TOC entry 3073 (class 0 OID 51489)
-- Dependencies: 201
-- Data for Name: picture; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('63aba729-5361-4b0c-80cc-1767b31af1a3', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAACUSURBVDhPtYxBDoIwFER7bBegB6BJ2UsibPEcbtwQ74KyozDJNL9i8WsIL5lk8v/MmMChqPw3HV3zYDQNQmvgZ6vrmJd1x/gn2kD/Grw9t+PJNXdW3tEGQP8cfDGPZO5yY03QBpZiTcDxV/YfgE8pAM+aEAc01AH4WEtwY01IBddQB+BTCsCzJsQBjf0G/hFrWzFmAnVrUV9JMRuGAAAAAElFTkSuQmCC', 'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAYAAAA7MK6iAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAACZSURBVEhL7Y2xDYAwEAMzNgUTQMEAUNCyByOB6ABZ+gJFhCf+NFFykgtHeZ+rgKafLibtMK8ywYGRWHDTjctpkrPibT9sclYMTHKLGNByqxhQclYciszq4HMqqvgTX4wekyfoMqvjH1vIU4z+J2/gXWZ1QiMMeYrRY/IEXWZ1/GMLeYrR/+QNvMusTmiEoYo/KVOcMjJbNM7dlkMYXKQcUGAAAAAASUVORK5CYII=', 'file', 'icons8-doc-16.png', 'https://icons8.ru/icon/21073/документ');
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('b18abc1d-8c6b-4117-8573-730f615a44bb', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlz
AAALEwAACxMBAJqcGAAAAOBJREFUOI3F0TFOAkEYxfH/N5BgxRko4AySaMJug7tYQuIJLAwXwNhL
Q2iNBQdAduhIsCDYcQFLCq9hsTM2LAlxgZlteNU0v5eXb+ASCWad6+ytfHE4jx8Fuwl1NAIQX0zK
Oypzduy84B82WCxbpwW5WGx/3Vu+7Re0pu26L4bdEYMkekGVvgN9d++DASRM4meEVwBj+BVlul/d
z4ULBihboZodQikqxigdJvGElKdzGHbfGOh4KDDIveAJDFAC+PnYrmoPjSuBWx+8L8gtccAHBQcl
hhsXfDQtHTULwSL5A1bQd3cpUSUSAAAAAElFTkSuQmCC', 'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAAAlwSFlz
AAALEwAACxMBAJqcGAAAAYFJREFUWIXt1L9Kw0AcwPHv71p8AEcRFHRy9QGadLAJWhcFB2dx8F/f
xFoFUZ+gNNdJ8M9SfQknBQcHX6J3LlqCpmlir1n0Nx45Pl+S3MH//JXxdG3Vj4IzLBJfV0XhFrqI
7Hm6dhGPkLSNLnGFmvpas9ZcPWzc7SLYUtE4gIgszz8tzLy2X64n9gYq3XANa/R3PD4WzifyD2TB
DaaP5dH5G8iKi1XbD5s3bacBeXEAZz9hNQrqFpsLB0fHsBoF9b7YKC8OCReR3w13Ku2VxSLwHwFV
HTSwXCpV6mWJGBeH2Ceo6qBhkePYzjdj+v7j1v1z0kZf19YNdMbBBwE/8BERrnAAGYoPiXCJA5SN
kTlJuw8Vs4pSr9Je8VVZllzi8PkJfB00QY7SHzXvBqZd4oOA7BEpeb/AIXYMexu3DSytInFIuAn9
KDxBOCwCTwzIEzEuPjQAwOuELVEcTBJPDUiLcIWPDEiKcIlnCgDwdHAqyL5rPNf4Omh6UbhVOPw/
k54P3y4apFxanTsAAAAASUVORK5CYII=', NULL, NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('3d947b1e-af43-438c-bdbd-ccab6d6020c6', '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', NULL, NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('9a29b793-a2e0-42b2-bf87-a5904faddf2e', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAGmSURBVDhPzZK/L0NRFMefHzUQidFoJqYXguC+
U+rd0zZMjR9h8RcYDBKJ2gyEkBhsIqj2vtuKtYkiEpHYLVbEr8VkkNQ5r7epoiaDT/Jy3v2eH/fc
c6/1p8RSsTrHk/PgDT0JjS+g8drYR/DknL1lB0zod3oOhxsdjWeOlsfB9FCnlbeqfAdZoWWX0O4p
FcqFdkINvv4VUKgocI+6qDFSGfaVHeAY8HDXSCVEWvaCDt1Xqi50WAoPL92E28LHG9Cyw7gKUNVN
x8NlsyyDk7v38K1bw7uj3QjFrjsK14y7AIknQslJ/hepcLMvEmXJHo6yBkpO0yyyfkARLgBeeIqG
uMQT789g++dkms2YCa1YYBO0XCHHIn353gQ+F5NBueMmzIfa36BuVs2yAKhwjzjAB77KYpGfkkVm
pImLQyZiG6kEdZGgVpMiJ2rpMS3QesK4fPgR0e5pKr5tpHL4CvkRgXbPg8rti8fj1ayzddJSQAov
KDkbPYrW+wk/wbvQLGbhAO9gf/C1T+ENW6HwNqjlDHdnQn+Hd6XztwnlOsGkbC128x+xrA8BzsDI
G6YyywAAAABJRU5ErkJggg==', 'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAKDSURBVFhH7ZU7ixRBEMdHAx8gGCg+Eg38AkZy
oGdP76u7xxXxcQZe4n2Jw0Dc0EAM/AQmh6sz3eMDuUDQQ4w0MjG6QBRR8IGPSDRY699bs5y6e9s3
K8jB/GCY7uqe/tdUd1VHFRXriqlbZ7ZKZ+ZiqxaPdM1Havf8Y1sfZGbuC6vOi+tiC0//t8gsOStv
mrcDUWeWY6cf0XsJ7cI+7VpvZK5O8WeT0+l0NkprrnkB+tPYmnmRJnt4eMC0U3ul1ReEM5/6zuir
+JaHy1OIx5l+IO61d7J5JE3X3CUy9dB/Y80VNpfDh53FZ9KZTWwei17Um3l7enGenGDz2vAHDntO
YQ/5c1DP6zsoYl1EoXb3+G7ZVZ+F06/gEE8Jh7yf4zDOs2lVIH40Nc/xDZ2DF3BCWnXRr+H0LE8L
B6nmFxty4P5kpTieqQXznbat3kjb+7zN6js8NRzO82XujmSouFPHeDjCFkjXfMfdcLAYDhJ3I3E7
OdhIG9u56xknDuhMPMEYd8PhRZfQruWtQ4ed+SKseVo4ESIOyjuA8kpbIFKxjd7vC6E4Nc9krg+E
iAMq0a+RTdwNB7Udi6PC1Zw+Se0fhaBcMD+L9qriNtmPOXFmcjaFg4vFi1B5Rf8vJ8aIg9jqS/01
zDk2hYNbDRcLajtyGraVTowTR+TozHylSL5cSxX9DSpCpyGG2l5UM+/EjcY3ikziJw0BzgunHvtv
c9Nmczlwq2EhpCTKK2zIAD84BP/nLB47c5nN5cGVilsNC6K2o7yiwvHwABw47LkPeyHeizbw8OTg
VutXtf4B9G3kOB6kGtux5xOHfRR8zc6itqO8DkQpz5FqOO2lD1xFRcX/IYp+AXKOqIevI8w2AAAA
AElFTkSuQmCC', NULL, NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('ad3f724f-6759-40f1-a69e-ca04137f4aa9', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlz
AAALEwAACxMBAJqcGAAAAYtJREFUOI1jYCASTE5md52fxrGZWPUoYEoah82KQr5n71ca/p+WwHIP
WY6JGM0i3GyrAhzUJTk5WBgivXQUpyIZgtcAZM0wMU52VoYoT13FqYksd/AagE0zDHz69uM3Nyfb
ZQYGBgZGUjW/fPfl984jd0+mzf1li9UAUjRjGECqZgYGpDCYmy8fSapmBgYGBhYYg5NHuEaeh0GA
FM0oLhBUtHrw5J8S47mbr74Rq5mBgYGBpWPWQfc3T+9dfPB4J6eRRTjHk7Orvp++cf+3ggQnA0xz
/aorPNyf3jSVpTgUwTS2zj0kyvr/vyHTf8b/lbwCwopzVhyT3bR5+yM+eYt797/Ks+w88eIyzGbu
dx/E//5jzEO2mfX/P5X/DP/KWRgYGBjYefj/mmoJWHMwf+L99PT6z9fSxQ/ZGXfnMzBMwuVyzECc
sf7SKwYGhlcMDAwMnbPzGP6LeT0kxgDGjrkHuv7/Z8xj+sfwHyb4l+H/F2YGRh64qn8MDH9Z/n9h
/ocQ+8f4n5GJiaEPAMEqxfEJUPMVAAAAAElFTkSuQmCC', 'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAAAlwSFlz
AAALEwAACxMBAJqcGAAAAoVJREFUWIXFlk1IFFEAx3/vzUxradoKYVJamHspo0NZh2Ajt2tdEgqi
IOwS0c2UkBCxSMM+oA6Bdulkp9Q62YcsgR0NykKXJIySWhNtVVy3mdchrdQZd3R3tj8MzMef9/u9
gTfzBB6k5TghJegCblS3Uy9AOXWFJ3B4giBr7tbV6nYuO0lIL+BCE77Qvm3k5vgUUNdygkblMFnN
C/iRYEAEivMJFPnFh8/jKj5rBnvL0Lvf0tPghcBi+NbCPADWGFpSiZQFnODzSSaRkkAyuBuJVQu4
hS+W6Bv4ChDs3cmnp/30rWoVrBQ+n4mp+N8LwQSAnin4l2iMjp5BBZhKUVnzkM7fHhmEm6a1AL4i
AS/grgW8grsS8BKeVMBr+LICmYA7CmQKDja/45unfIeV4JmQIstruK2AkbX+EoChS4oKcj2F2woU
luzvyt6w2ZpNmHS/GsKyHHdTKcNtBaRvXbxkb2UiryBAZHhsWYlU4bYCAEIz2BW6wHIS6YDbCkxO
J3QAafgcJdIFB9CbWnvOKCVOSinv1p4NdnSGB3eU79HloU2BPxJvnt8hMhwBoKx0I13hiC382v2X
u6WyXgPUnj3o+I253hY+ZlrqnKbxQAoht0spQkqpLQDR75P5t1q79feDH1HKQugGZRXnySsoJTI8
xqMXAzjO3PrpdzNrS1AkpQgpS5Qs2Q+Mjk/3S02pptut1sXTB2b8uWsVgL+4PCc+/YOZ2DdSfe3/
ZonAu6HRJuDeCDGqGjpngBhAc1tYUV6FHAkfralvfJwOONivggQQnTtiC9sGZmFFNF1wJ4GM5r8L
iOa28BWgDsCymHIqSkn2/LlTz01nQU/RoNs+SBI3Pbdj/QKw6ffaetabSgAAAABJRU5ErkJggg==', NULL, NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('8d491ef2-a8de-418b-8b88-64238e550663', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('00e5691b-1e20-4f15-991a-aaf896bcded8', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAByUlEQVR4XpWSQWsTQRiGn5nZZBvR
Iga0QhoP6kl6KnopHgQvniw0IeDBk14UBC+KJ/FP6G8oUsnF0970pC0iFZoNFOxiSIpWWoxbs5sm
6zCbzUYTA77wsN+w8z0zfLsiiiKEEOeARf4vm7p32yLOYqcTrIVhgBBSg0YY0Aj+jGVZZDKZFWAo
IAgC/EMfKRVf20e8fL9HzlZ83PlJIZ/j4Y0CszMKiOVJZFIIKVBKaSSPVne4f73APc2z0nnW1vd4
7rQG79VkgRQCKaVhq+HjbB2Yej4/w9LFk7yt/0DGArMniZUUYiBQmtUHC1yYO2Zqoak1D7m1NGfW
yWz+JTAszB9HDpq3d3/RCfvcvno2OXm6QBhJSnXjG0/1HPKzNpNikRqQMYnASFv7XZ4sn0lOnfIV
0lsMN+wehCxfOW3WCVNvIOLmISdyFtcunTJ1r9ej2+2aZzabjSbfAEYFvHC+8OpdyzS12208z6PZ
bFKtVteBWiqIGbvmG/c7Hz7vE4YhjUaDYrGI67pepVK5C7hjQ/w7rx9fpt/v4/u+ETuO45XL5ZvA
p0hnVBD/YePDMrVt21G9Xt8olUp3RptHBZuWUitMTw1w4+Y0vwGrVZjGwBAjNgAAAABJRU5ErkJg
gg==', 'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAADzklEQVR4XrWWzWsTWxjGn8w0qU2M
sSKm9gqmtbfpxU2tUAQj3I0b2+JFrFgRpFDQu3OrQhFcuVSX/gcKbly4kLvxq9iKH71+EGsGP0qj
/TSNNmFmMuN7Jh9nwsn0xJa+8PCeDIHfM897zkl8tm2jXD6fTwFA2tCyiGlVmPShDFcBNJO2baAJ
Bl4kLRG3AKoG8PKTOr9nMo8NXWeO4CsLcH8uGuaxldPjSfLnVVJVFcGmpoMAnpMEA4wTMHQDumGW
YFyKwkHOSuyecF91D/AlN8BVhFETRSWsXV00wiWk5GXAAy6MQp5CrSQURW6AIKXInS9LDHh00Yyw
loxAESIvCzZw59kcHiUz0GbzWM4X0NUSxL+Hd6EnFi7D1zMCBZZl8Wi5nHwu3U6hZWsjLh5tQ0sk
gGQ6h5Gb7zB04w0uHI1h+O9WAS6cFOkIePRVJia0LO6/XsT4lV40qIoD+uuPEK6diePk9de4evcT
DnU1o3NnkAMlCSioVUWwkMAzbRmLP0zcfjoLxfV8f9sWhDapsC04o/HxMQqSGuBQUTsijU6f/Pyz
CC9BChaYKmsOEiUfwSoGjvVGEQn6caAjUvVG/3/JwjRtKCyN9rCnAXq+PgMBFTjSvV2IdCK17MD3
7gqhh8bhAq7BgLc85/ni4w/nArt8Yo+zOSUlGpCn4H0tL/00MP5hGefoHtgXE95eKkV+AkS5AbfG
ZtFDcz9/ZLfXbhee1X0PQAKnTm+fweXje6AqHLCeTcih1Xd3TbhlA7EdTWiPBj0Brn9c9SdgiyNA
rdK+5ZDoauZwDnVrDQmQa0JKf/8bVB8O/BmpgluW5VaVCVVV60yg9sYRTLRR/G54oVBgUNaZuAlu
gC1MhpAdw5pAdy1kDYze0nAwHsFQYidgF2GmaULXdRiGwdYlEywFC5OTk2MApknGagbq2s33Xi7g
wdslPHz3HfHWILp3hxjQAc/Pz2Nubg6sQqEQ/H4/UqnU+4GBgbMA0pRIQTAggQvPeju2ILq1EdFI
Izqimyqx5/N5pNNpJBIJrKysYGZmBslkcprgQwA0kl7PTSg1E28N4b/RHjZfBmaxs85SoG4hl8s5
RjRNmz9FBSBJytlU8puw/rEwA+5d74wgHN7M4Cz2heHh4dPZbPYVgBUO51JkMEkJZ56SYHN3Yh8c
HPyHjDwBkBXgwgikkhtkI6Bisb/v6+s7AeCD+81lBmySqSoKi1W4gDzir/z9ojPOdrs9NTU11t/f
PwLgIynP4XIDJmk6EAgcWkcyOukzaZZkCHCJgULpkvi6NjZPkZ9zef0Cr8CvkmRTUJgAAAAASUVO
RK5CYII=', NULL, NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('dbc0b7fb-7bb3-4214-b87c-1e3d2157c2dd', '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
4GFWtekrAPlGvZWXjlAAAAAASUVORK5CYII=', NULL, NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('df3a2195-d3ad-4779-b865-051159c27454', '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
aQAAAABJRU5ErkJggg==', NULL, NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('32a8d594-ac1c-49b3-a89b-e79080452942', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('fd7628f8-a276-4d4a-bc54-8b6363902919', NULL, NULL, 'book', NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('4fa5d174-ecee-4634-9973-6d4be41413f1', NULL, NULL, 'cogs', NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('ad84a7b0-cd67-4f46-bdb8-f9ec6b4c7a25', NULL, NULL, 'file-alt', NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('ba9f4e27-8458-4416-be25-de1f709d756d', NULL, NULL, 'wrench', NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('9ff4c34c-76f3-4658-b209-e5ccc5aea521', NULL, NULL, 'users', NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('7d656422-6b5b-46d8-a520-50c6b0d6a430', NULL, NULL, 'user-circle', NULL, NULL);
INSERT INTO public.picture (id, size16, size32, fa_name, img_name, note) VALUES ('0a6136b7-8739-48ed-8673-f78a4be35a8c', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQBAMAAADt3eJSAAAAJ1BMVEUAAACZfEWafUefgUmdgUmWekShg0vGoFvPrWrUqmLbsGXzzIT1zoW2jJ2UAAAABXRSTlMAfX72/YS78zAAAAAvSURBVAjXY2CAgdDQQAgjatVkBShjuWsoEAClwrrPnDlzlCHmDBhQjxEKBXBXAADqt0KEAlPQ8gAAAABJRU5ErkJggg==', 'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAYAAAA7MK6iAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAACnSURBVEhLYxgFdAXTqlz+E8Kzal1boMqpB0AG396QihNfXZP8f36D5xeqW07IYhCmieXEWAzCF1Yk/J9T7/4HFvzkYqi1xFl8ZF70/7kNHv8PLUz6/+lM8/+v51rJwhgWE8JL2nz/P9hTjtUwUjDILKi1EIuxKaIFHrUYqyJa4FGLsSqiBR61GKsiWuBRi7EqogUetRirIlrgwWMxPTHU2lFAD8DAAABGJXxDR2ZBXgAAAABJRU5ErkJggg==', 'folder', 'icons8-folder-16.png', 'https://icons8.ru/icon/21079/папка');


--
-- TOC entry 3072 (class 0 OID 51484)
-- Dependencies: 200
-- Data for Name: status; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.status (id, code, note, picture_id) VALUES (1005, 'not installed', 'Не установлен', 'df3a2195-d3ad-4779-b865-051159c27454');
INSERT INTO public.status (id, code, note, picture_id) VALUES (1004, 'is changing', 'Изменяется', 'ad3f724f-6759-40f1-a69e-ca04137f4aa9');
INSERT INTO public.status (id, code, note, picture_id) VALUES (1003, 'expired', 'Утратил силу', '3d947b1e-af43-438c-bdbd-ccab6d6020c6');
INSERT INTO public.status (id, code, note, picture_id) VALUES (1002, 'approved by', 'Утвержден', '9a29b793-a2e0-42b2-bf87-a5904faddf2e');
INSERT INTO public.status (id, code, note, picture_id) VALUES (1001, 'correct', 'Корректен', 'b18abc1d-8c6b-4117-8573-730f615a44bb');
INSERT INTO public.status (id, code, note, picture_id) VALUES (1000, 'compiled', 'Составлен', '63aba729-5361-4b0c-80cc-1767b31af1a3');
INSERT INTO public.status (id, code, note, picture_id) VALUES (0, 'unknown', 'Не установлено', '00e5691b-1e20-4f15-991a-aaf896bcded8');
INSERT INTO public.status (id, code, note, picture_id) VALUES (1006, 'installed', 'Установлен', 'dbc0b7fb-7bb3-4214-b87c-1e3d2157c2dd');
INSERT INTO public.status (id, code, note, picture_id) VALUES (500, 'folder', 'Папка', '0a6136b7-8739-48ed-8673-f78a4be35a8c');


--
-- TOC entry 3078 (class 0 OID 51834)
-- Dependencies: 206
-- Data for Name: transition; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.transition (id, name) VALUES ('75d6daef-1269-4aa9-af79-48e17f4389da', 'Без состояний');
INSERT INTO public.transition (id, name) VALUES ('0a27ee87-8fa1-49bd-a76c-0014081dfdec', 'Справочник без утверждения');
INSERT INTO public.transition (id, name) VALUES ('5099ac3d-81d3-4e83-a2e6-5d0dab48dbde', 'Справочник с утверждением');
INSERT INTO public.transition (id, name) VALUES ('dafae4fd-8139-4b43-b6b9-9120500730dc', 'Дополнения');


--
-- TOC entry 3159 (class 0 OID 0)
-- Dependencies: 208
-- Name: access_list_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.access_list_id_seq', 4, true);


--
-- TOC entry 3160 (class 0 OID 0)
-- Dependencies: 203
-- Name: history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.history_id_seq', 1, true);


--
-- TOC entry 3161 (class 0 OID 0)
-- Dependencies: 213
-- Name: log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.log_id_seq', 36, true);


--
-- TOC entry 2876 (class 2606 OID 52032)
-- Name: access_list access_list_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_list
    ADD CONSTRAINT access_list_pkey PRIMARY KEY (id);


--
-- TOC entry 2886 (class 2606 OID 52187)
-- Name: addon addon_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.addon
    ADD CONSTRAINT addon_pkey PRIMARY KEY (id);


--
-- TOC entry 2868 (class 2606 OID 51914)
-- Name: changing_status changing_status_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.changing_status
    ADD CONSTRAINT changing_status_idx UNIQUE (transition_id, status_from_id, status_to_id);


--
-- TOC entry 2870 (class 2606 OID 51895)
-- Name: changing_status changing_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.changing_status
    ADD CONSTRAINT changing_status_pkey PRIMARY KEY (id);


--
-- TOC entry 2840 (class 2606 OID 51418)
-- Name: client client_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_name_key UNIQUE (name);


--
-- TOC entry 2842 (class 2606 OID 51416)
-- Name: client client_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_pkey PRIMARY KEY (id);


--
-- TOC entry 2878 (class 2606 OID 52112)
-- Name: command command_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.command
    ADD CONSTRAINT command_pkey PRIMARY KEY (id);


--
-- TOC entry 2880 (class 2606 OID 52125)
-- Name: constants constants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.constants
    ADD CONSTRAINT constants_pkey PRIMARY KEY (key);


--
-- TOC entry 2888 (class 2606 OID 53204)
-- Name: contractor contractor_inn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contractor
    ADD CONSTRAINT contractor_inn_key UNIQUE (inn);


--
-- TOC entry 2890 (class 2606 OID 53197)
-- Name: contractor contractor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contractor
    ADD CONSTRAINT contractor_pkey PRIMARY KEY (id);


--
-- TOC entry 2846 (class 2606 OID 51483)
-- Name: directory directory_code_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_code_idx UNIQUE (kind_id, code);


--
-- TOC entry 2850 (class 2606 OID 51476)
-- Name: directory directory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_pkey PRIMARY KEY (id);


--
-- TOC entry 2844 (class 2606 OID 51446)
-- Name: document_info document_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_info
    ADD CONSTRAINT document_info_pkey PRIMARY KEY (id);


--
-- TOC entry 2862 (class 2606 OID 51625)
-- Name: document document_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_pkey PRIMARY KEY (id);


--
-- TOC entry 2860 (class 2606 OID 51596)
-- Name: history history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_pkey PRIMARY KEY (id);


--
-- TOC entry 2856 (class 2606 OID 51544)
-- Name: kind kind_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kind
    ADD CONSTRAINT kind_code_key UNIQUE (code);


--
-- TOC entry 2858 (class 2606 OID 51542)
-- Name: kind kind_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kind
    ADD CONSTRAINT kind_pkey PRIMARY KEY (id);


--
-- TOC entry 2884 (class 2606 OID 52169)
-- Name: log log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);


--
-- TOC entry 2882 (class 2606 OID 52139)
-- Name: menu menu_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu
    ADD CONSTRAINT menu_pkey PRIMARY KEY (id);


--
-- TOC entry 2854 (class 2606 OID 51496)
-- Name: picture picture_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.picture
    ADD CONSTRAINT picture_pkey PRIMARY KEY (id);


--
-- TOC entry 2852 (class 2606 OID 51488)
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (id);


--
-- TOC entry 2864 (class 2606 OID 51841)
-- Name: transition transition_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transition
    ADD CONSTRAINT transition_name_key UNIQUE (name);


--
-- TOC entry 2866 (class 2606 OID 51839)
-- Name: transition transition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transition
    ADD CONSTRAINT transition_pkey PRIMARY KEY (id);


--
-- TOC entry 2871 (class 1259 OID 52067)
-- Name: access_list_changing_unq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX access_list_changing_unq ON public.access_list USING btree (client_id, access, changing_status_id) WHERE (changing_status_id IS NOT NULL);


--
-- TOC entry 2872 (class 1259 OID 52063)
-- Name: access_list_directory_unq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX access_list_directory_unq ON public.access_list USING btree (client_id, access, directory_id) WHERE (directory_id IS NOT NULL);


--
-- TOC entry 2873 (class 1259 OID 52064)
-- Name: access_list_document_unq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX access_list_document_unq ON public.access_list USING btree (client_id, access, document_id) WHERE (document_id IS NOT NULL);


--
-- TOC entry 2874 (class 1259 OID 52066)
-- Name: access_list_kind_unq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX access_list_kind_unq ON public.access_list USING btree (client_id, access, kind_id) WHERE (kind_id IS NOT NULL);


--
-- TOC entry 2847 (class 1259 OID 77796)
-- Name: directory_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX directory_name_idx ON public.directory USING btree (kind_id, parent_id, name) WHERE (parent_id IS NOT NULL);


--
-- TOC entry 2848 (class 1259 OID 77798)
-- Name: directory_name_root_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX directory_name_root_idx ON public.directory USING btree (kind_id, name) WHERE (parent_id IS NULL);


--
-- TOC entry 2945 (class 2620 OID 52081)
-- Name: access_list access_list_aiu; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER access_list_aiu AFTER INSERT OR UPDATE ON public.access_list NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE public.tr_access_list_check();


--
-- TOC entry 2946 (class 2620 OID 61364)
-- Name: contractor contractor_bi; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER contractor_bi BEFORE INSERT ON public.contractor FOR EACH ROW EXECUTE PROCEDURE public.tr_contractor_init();


--
-- TOC entry 2947 (class 2620 OID 77807)
-- Name: contractor contractor_biu; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER contractor_biu AFTER INSERT OR UPDATE ON public.contractor NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE public.tr_contractor_test_codes();


--
-- TOC entry 2933 (class 2620 OID 51973)
-- Name: directory directory_ad; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER directory_ad AFTER DELETE ON public.directory NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE public.tr_doc_info_check_remove();


--
-- TOC entry 2936 (class 2620 OID 52129)
-- Name: directory directory_ai; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER directory_ai AFTER INSERT ON public.directory FOR EACH ROW EXECUTE PROCEDURE public.tr_directory_ins_prop();


--
-- TOC entry 2938 (class 2620 OID 51978)
-- Name: directory directory_aiu; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER directory_aiu AFTER INSERT OR UPDATE ON public.directory NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE public.tr_doc_info_check_access();


--
-- TOC entry 2937 (class 2620 OID 52074)
-- Name: directory directory_au; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER directory_au AFTER UPDATE ON public.directory FOR EACH ROW EXECUTE PROCEDURE public.tr_doc_info_change_status();


--
-- TOC entry 2934 (class 2620 OID 52069)
-- Name: directory directory_bi; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER directory_bi BEFORE INSERT ON public.directory FOR EACH ROW EXECUTE PROCEDURE public.tr_doc_info_init();


--
-- TOC entry 2935 (class 2620 OID 52075)
-- Name: directory directory_bu; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER directory_bu BEFORE UPDATE ON public.directory FOR EACH ROW EXECUTE PROCEDURE public.tr_doc_info_update();


--
-- TOC entry 2940 (class 2620 OID 51975)
-- Name: document document_ad; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER document_ad AFTER DELETE ON public.document NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE public.tr_doc_info_check_remove();


--
-- TOC entry 2944 (class 2620 OID 52076)
-- Name: document document_aiu; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER document_aiu AFTER INSERT OR UPDATE ON public.document FOR EACH ROW EXECUTE PROCEDURE public.tr_doc_info_check_access();


--
-- TOC entry 2941 (class 2620 OID 52071)
-- Name: document document_au; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER document_au AFTER UPDATE ON public.document FOR EACH ROW EXECUTE PROCEDURE public.tr_doc_info_change_status();


--
-- TOC entry 2942 (class 2620 OID 52072)
-- Name: document document_bi; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER document_bi BEFORE INSERT ON public.document FOR EACH ROW EXECUTE PROCEDURE public.tr_doc_info_init();


--
-- TOC entry 2943 (class 2620 OID 52073)
-- Name: document document_bu; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER document_bu BEFORE UPDATE ON public.document FOR EACH ROW EXECUTE PROCEDURE public.tr_doc_info_update();


--
-- TOC entry 2939 (class 2620 OID 52070)
-- Name: history history_bi; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER history_bi BEFORE INSERT ON public.history FOR EACH ROW EXECUTE PROCEDURE public.tr_history_init();


--
-- TOC entry 2925 (class 2606 OID 52097)
-- Name: access_list access_list_changing_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_list
    ADD CONSTRAINT access_list_changing_fk FOREIGN KEY (changing_status_id) REFERENCES public.changing_status(id) ON DELETE CASCADE;


--
-- TOC entry 2921 (class 2606 OID 52033)
-- Name: access_list access_list_client_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_list
    ADD CONSTRAINT access_list_client_fk FOREIGN KEY (client_id) REFERENCES public.client(id) ON DELETE CASCADE;


--
-- TOC entry 2924 (class 2606 OID 52092)
-- Name: access_list access_list_directory_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_list
    ADD CONSTRAINT access_list_directory_fk FOREIGN KEY (directory_id) REFERENCES public.directory(id) ON DELETE CASCADE;


--
-- TOC entry 2923 (class 2606 OID 52087)
-- Name: access_list access_list_document_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_list
    ADD CONSTRAINT access_list_document_fk FOREIGN KEY (document_id) REFERENCES public.document(id) ON DELETE CASCADE;


--
-- TOC entry 2922 (class 2606 OID 52082)
-- Name: access_list access_list_kind_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_list
    ADD CONSTRAINT access_list_kind_fk FOREIGN KEY (kind_id) REFERENCES public.kind(id) ON DELETE CASCADE;


--
-- TOC entry 2930 (class 2606 OID 52188)
-- Name: addon addon_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.addon
    ADD CONSTRAINT addon_id_fk FOREIGN KEY (id) REFERENCES public.directory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2919 (class 2606 OID 51901)
-- Name: changing_status changing_status_from_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.changing_status
    ADD CONSTRAINT changing_status_from_fk FOREIGN KEY (status_from_id) REFERENCES public.status(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2920 (class 2606 OID 51906)
-- Name: changing_status changing_status_to_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.changing_status
    ADD CONSTRAINT changing_status_to_fk FOREIGN KEY (status_to_id) REFERENCES public.status(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2918 (class 2606 OID 51896)
-- Name: changing_status changing_status_transition_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.changing_status
    ADD CONSTRAINT changing_status_transition_fk FOREIGN KEY (transition_id) REFERENCES public.transition(id) ON DELETE CASCADE;


--
-- TOC entry 2891 (class 2606 OID 51699)
-- Name: client client_parent_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_parent_fk FOREIGN KEY (parent_id) REFERENCES public.client(id) ON DELETE CASCADE;


--
-- TOC entry 2926 (class 2606 OID 52113)
-- Name: command command_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.command
    ADD CONSTRAINT command_id_fk FOREIGN KEY (id) REFERENCES public.directory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2931 (class 2606 OID 53198)
-- Name: contractor contractor_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contractor
    ADD CONSTRAINT contractor_id_fk FOREIGN KEY (id) REFERENCES public.directory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2932 (class 2606 OID 53205)
-- Name: contractor contractor_okopf_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contractor
    ADD CONSTRAINT contractor_okopf_fk FOREIGN KEY (okopf_id) REFERENCES public.directory(id) ON DELETE SET NULL;


--
-- TOC entry 2892 (class 2606 OID 51460)
-- Name: directory directory_client_created_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_client_created_fk FOREIGN KEY (client_created_id) REFERENCES public.client(id);


--
-- TOC entry 2894 (class 2606 OID 51470)
-- Name: directory directory_client_locked_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_client_locked_fk FOREIGN KEY (client_locked_id) REFERENCES public.client(id);


--
-- TOC entry 2893 (class 2606 OID 51465)
-- Name: directory directory_client_updated_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_client_updated_fk FOREIGN KEY (client_updated_id) REFERENCES public.client(id);


--
-- TOC entry 2900 (class 2606 OID 51666)
-- Name: directory directory_history_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_history_fk FOREIGN KEY (history_id) REFERENCES public.history(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 2899 (class 2606 OID 51561)
-- Name: directory directory_kind_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_kind_fk FOREIGN KEY (kind_id) REFERENCES public.kind(id);


--
-- TOC entry 2895 (class 2606 OID 51477)
-- Name: directory directory_owner_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_owner_fk FOREIGN KEY (owner_id) REFERENCES public.directory(id) ON DELETE CASCADE;


--
-- TOC entry 2896 (class 2606 OID 51512)
-- Name: directory directory_parent_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_parent_fk FOREIGN KEY (parent_id) REFERENCES public.directory(id) ON DELETE CASCADE;


--
-- TOC entry 2897 (class 2606 OID 51517)
-- Name: directory directory_picture_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_picture_fk FOREIGN KEY (picture_id) REFERENCES public.picture(id) ON DELETE SET NULL;


--
-- TOC entry 2898 (class 2606 OID 51527)
-- Name: directory directory_status_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directory
    ADD CONSTRAINT directory_status_fk FOREIGN KEY (status_id) REFERENCES public.status(id) ON UPDATE CASCADE;


--
-- TOC entry 2914 (class 2606 OID 51651)
-- Name: document document_client_created_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_client_created_fk FOREIGN KEY (client_created_id) REFERENCES public.client(id);


--
-- TOC entry 2916 (class 2606 OID 51661)
-- Name: document document_client_locked_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_client_locked_fk FOREIGN KEY (client_locked_id) REFERENCES public.client(id);


--
-- TOC entry 2915 (class 2606 OID 51656)
-- Name: document document_client_updated_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_client_updated_fk FOREIGN KEY (client_updated_id) REFERENCES public.client(id);


--
-- TOC entry 2917 (class 2606 OID 51671)
-- Name: document document_history_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_history_fk FOREIGN KEY (history_id) REFERENCES public.history(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 2913 (class 2606 OID 51646)
-- Name: document document_kind_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_kind_fk FOREIGN KEY (kind_id) REFERENCES public.kind(id);


--
-- TOC entry 2912 (class 2606 OID 51641)
-- Name: document document_owner_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_owner_fk FOREIGN KEY (owner_id) REFERENCES public.document(id) ON DELETE CASCADE;


--
-- TOC entry 2911 (class 2606 OID 51636)
-- Name: document document_status_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_status_fk FOREIGN KEY (status_id) REFERENCES public.status(id) ON UPDATE CASCADE;


--
-- TOC entry 2906 (class 2606 OID 51597)
-- Name: history history_client_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_client_fk FOREIGN KEY (client_id) REFERENCES public.client(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2909 (class 2606 OID 51615)
-- Name: history history_directory_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_directory_fk FOREIGN KEY (directory_id) REFERENCES public.directory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2910 (class 2606 OID 51626)
-- Name: history history_document_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_document_fk FOREIGN KEY (document_id) REFERENCES public.document(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2907 (class 2606 OID 51602)
-- Name: history history_status_from_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_status_from_fk FOREIGN KEY (status_from_id) REFERENCES public.status(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2908 (class 2606 OID 51607)
-- Name: history history_status_to_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_status_to_fk FOREIGN KEY (status_to_id) REFERENCES public.status(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2903 (class 2606 OID 51551)
-- Name: kind kind_picture_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kind
    ADD CONSTRAINT kind_picture_fk FOREIGN KEY (picture_id) REFERENCES public.picture(id) ON DELETE SET NULL;


--
-- TOC entry 2905 (class 2606 OID 51955)
-- Name: kind kind_start_status_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kind
    ADD CONSTRAINT kind_start_status_fk FOREIGN KEY (start_status_id) REFERENCES public.status(id) ON UPDATE CASCADE;


--
-- TOC entry 2904 (class 2606 OID 51878)
-- Name: kind kind_transition_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kind
    ADD CONSTRAINT kind_transition_fk FOREIGN KEY (transition_id) REFERENCES public.transition(id) ON DELETE SET NULL;


--
-- TOC entry 2929 (class 2606 OID 52175)
-- Name: log log_client_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_client_fk FOREIGN KEY (client_id) REFERENCES public.client(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2928 (class 2606 OID 52146)
-- Name: menu menu_command_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu
    ADD CONSTRAINT menu_command_fk FOREIGN KEY (command_id) REFERENCES public.command(id) ON DELETE SET NULL;


--
-- TOC entry 2927 (class 2606 OID 52140)
-- Name: menu menu_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu
    ADD CONSTRAINT menu_id_fk FOREIGN KEY (id) REFERENCES public.directory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2902 (class 2606 OID 51497)
-- Name: picture picture_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.picture
    ADD CONSTRAINT picture_id_fk FOREIGN KEY (id) REFERENCES public.directory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2901 (class 2606 OID 51522)
-- Name: status status_picture_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_picture_fk FOREIGN KEY (picture_id) REFERENCES public.picture(id) ON DELETE SET NULL;


--
-- TOC entry 3098 (class 0 OID 0)
-- Dependencies: 723
-- Name: TYPE access_right; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.access_right TO admins;


--
-- TOC entry 3099 (class 0 OID 0)
-- Dependencies: 722
-- Name: TYPE access_value; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.access_value TO admins;


--
-- TOC entry 3100 (class 0 OID 0)
-- Dependencies: 721
-- Name: TYPE command_type; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.command_type TO admins;


--
-- TOC entry 3101 (class 0 OID 0)
-- Dependencies: 677
-- Name: TYPE kind_type; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.kind_type TO admins;


--
-- TOC entry 3102 (class 0 OID 0)
-- Dependencies: 262
-- Name: FUNCTION okopf_select(did uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.okopf_select(did uuid) TO admins;


--
-- TOC entry 3103 (class 0 OID 0)
-- Dependencies: 209
-- Name: TABLE access_list; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.access_list TO admins;


--
-- TOC entry 3105 (class 0 OID 0)
-- Dependencies: 215
-- Name: TABLE addon; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.addon TO admins;


--
-- TOC entry 3106 (class 0 OID 0)
-- Dependencies: 207
-- Name: TABLE changing_status; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.changing_status TO admins;


--
-- TOC entry 3112 (class 0 OID 0)
-- Dependencies: 197
-- Name: TABLE client; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.client TO admins;
GRANT SELECT ON TABLE public.client TO guest;


--
-- TOC entry 3113 (class 0 OID 0)
-- Dependencies: 210
-- Name: TABLE command; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.command TO admins;


--
-- TOC entry 3114 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE constants; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.constants TO admins;


--
-- TOC entry 3121 (class 0 OID 0)
-- Dependencies: 216
-- Name: TABLE contractor; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.contractor TO admins;


--
-- TOC entry 3131 (class 0 OID 0)
-- Dependencies: 198
-- Name: TABLE document_info; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.document_info TO admins;


--
-- TOC entry 3136 (class 0 OID 0)
-- Dependencies: 199
-- Name: TABLE directory; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directory TO admins;


--
-- TOC entry 3138 (class 0 OID 0)
-- Dependencies: 205
-- Name: TABLE document; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.document TO admins;


--
-- TOC entry 3140 (class 0 OID 0)
-- Dependencies: 204
-- Name: TABLE history; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.history TO admins;


--
-- TOC entry 3148 (class 0 OID 0)
-- Dependencies: 202
-- Name: TABLE kind; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.kind TO admins;


--
-- TOC entry 3149 (class 0 OID 0)
-- Dependencies: 214
-- Name: TABLE log; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.log TO admins;


--
-- TOC entry 3151 (class 0 OID 0)
-- Dependencies: 212
-- Name: TABLE menu; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.menu TO admins;


--
-- TOC entry 3153 (class 0 OID 0)
-- Dependencies: 201
-- Name: TABLE picture; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.picture TO admins;


--
-- TOC entry 3157 (class 0 OID 0)
-- Dependencies: 200
-- Name: TABLE status; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.status TO admins;


--
-- TOC entry 3158 (class 0 OID 0)
-- Dependencies: 206
-- Name: TABLE transition; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.transition TO admins;


-- Completed on 2018-12-19 23:43:34

--
-- PostgreSQL database dump complete
--

