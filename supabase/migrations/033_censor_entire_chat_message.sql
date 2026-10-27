create or replace function public.chat_censor_message(message_body text)
returns text
language plpgsql
immutable
set search_path=''
as $$
declare
 clean text:=message_body;
 word text;
 words text[] := array[
  'pendejo','pendeja','pendejos','pendejas','idiota','idiotas',
  'estupido','estupida','estupidos','estupidas','imbecil','imbeciles',
  'cabron','cabrona','cabrones','cabronas','chingar','chingada','chingado',
  'chingados','verga','vergas','puto','puta','putos','putas','maricon',
  'marica','joto','jotos','mierda','mierdas','culo','culos','polla','pollas',
  'pene','penes','vagina','vaginas','vulva','vulvas','teta','tetas',
  'senos','seno','nalga','nalgas','coño','cono','zorra','sexo','sudaca',
  'wetback','nigger','negrata'
 ];
begin
 foreach word in array words loop
  if clean ~* ('\m'||word||'\M') then
   return regexp_replace(clean, '\S', '#', 'g');
  end if;
 end loop;
 return clean;
end;
$$;
