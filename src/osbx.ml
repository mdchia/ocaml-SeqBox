open Cmdliner

let help_secs = [ `S Manpage.s_common_options
                ; `P "These options are common to all comamnds."
                ; `S "MORE HELP"
                ; `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command."
                ; `S Manpage.s_bugs
                ; `P "Report bugs at ocaml-SeqBox github page via issues (https://github.com/darrenldl/ocaml-SeqBox)"
                ]
;;

let default_cmd =
  let doc = "a SeqBox implementation written in OCaml" in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let man = help_secs in
  Term.(ret (const (`Help (`Pager, None)))),
  Term.info "osbx" ~version:"v1.0.0" ~doc ~sdocs ~exits ~man
;;

let encode_cmd =
  let open Osbx_encode in
  let doc = "encode file" in
  (Term.(const encode $ force $ no_meta $ uid $ in_file $ out_file),
   Term.info "encode" ~doc
  )
;;

let () =
  Term.exit @@ Term.eval_choice default_cmd [encode_cmd]
;;
