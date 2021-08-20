module OptionSyntax = struct
  let ( let* ) = Option.bind

  let ( let+ ) a b = Option.map b a
end

let temp_filename =
  let uid = Int.to_string (Unix.getuid ()) in
  (* Filename.concat (Filename.get_temp_dir_name ()) ("cputime_" ^ uid) *)
  "/var/run/user/" ^ uid ^ "/blocks_cputime"

let find_cpu line =
  match String.split_on_char ' ' line with
  | "cpu" :: "" :: user :: nice :: system :: idle :: _iowait :: etc ->
      let open OptionSyntax in
      let* total_used =
        user :: nice :: system :: etc
        |> List.fold_left
             (fun acc el ->
               let* n = acc in
               let+ this = int_of_string_opt el in
               this + n)
             (Some 0)
      in
      let+ total_unused = int_of_string_opt idle in
      (total_used, total_unused)
  | _ -> None

let with_file filename f =
  let fh = open_in filename in
  Fun.protect ~finally:(fun () -> close_in fh) (fun () -> f fh)

let read_cpu () =
  with_file "/proc/stat" (fun f ->
      let result = ref None in
      (try
         while !result = None do
           let line = input_line f in
           result := find_cpu line
         done
       with End_of_file -> ());
      !result)

let read_old_values () =
  try
    with_file temp_filename (fun f ->
        let open OptionSyntax in
        let* last_cpu_used = int_of_string_opt @@ input_line f in
        let+ last_cpu_unused = int_of_string_opt @@ input_line f in
        (last_cpu_used, last_cpu_unused))
  with
  | Sys_error _ -> None
  | End_of_file -> None

let write_values cpu_used cpu_unused =
  let f = open_out temp_filename in
  Fun.protect
    ~finally:(fun () -> close_out f)
    (fun () ->
      output_string f @@ Int.to_string cpu_used ^ "\n";
      output_string f @@ Int.to_string cpu_unused ^ "\n")

let calc_cpu_diff () =
  let open OptionSyntax in
  let oldvals = read_old_values () in
  let* cpu_used, cpu_unused = read_cpu () in
  write_values cpu_used cpu_unused;
  let+ old_cpu_used, old_cpu_unused = oldvals in
  let cpu_used_diff = cpu_used - old_cpu_used in
  let cpu_unused_diff = cpu_unused - old_cpu_unused in
  let cpu_total_diff = cpu_used_diff + cpu_unused_diff in
  Float.of_int cpu_used_diff /. Float.of_int cpu_total_diff

let main () =
  let cpu_usage = calc_cpu_diff () |> Option.value ~default:Float.nan in
  let cpu_percent = 100. *. cpu_usage in
  Printf.printf "%.2f%%\n" cpu_percent

;;
main ()
