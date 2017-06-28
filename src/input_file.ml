open Core
open Nocrypto.Hash
open Sbx_version

type hash_state_and_chunks = SHA256.t * (string list)

type multihash_and_chunks  = string * (string list)

let file_hash_and_split ~(ver:version) ~(filename:string) : multihash_and_chunks =
  let read_block_size : int    = ver_to_data_size ver in
  let buf             : string = String.make read_block_size '\x00' in  (* Core.In_channel.input needs the buffer to be string instead of bytes as of time of writing - 2017-06-28 *)
  (* let buf             : bytes = Bytes.create read_block_size in *)

  let rec acc_chunks ~(acc:hash_state_and_chunks) ~(pos:int) ~(file:In_channel.t) : hash_state_and_chunks =
    print_endline "flag A";
    let (hash_state, chunks)       = acc in
    print_endline "flag B";
    (* let read                       = In_channel.really_input file ~buf ~pos ~len:read_block_size in
    ignore (
      match read with
      | Some x -> Printf.printf "got something\n"
      | None   -> Printf.printf "got nothing\n"
    ); *)
    let read_count           : int = In_channel.input        file ~buf ~pos:0 ~len:read_block_size in
    Printf.printf "read count : %d\n" read_count;
    Printf.printf "buffer     : %s\n" (Hex.hexdump_s (Hex.of_string buf));
    (* let read_count                 = if read_count > 0 then read_count - 1 else read_count in (* adjust read_count *) *)
    let new_chunk                  = Bytes.create read_count in
    String.blit ~src:buf ~src_pos:0 ~dst:new_chunk ~dst_pos:0 ~len:read_count; (* copy content from buffer to new chunk*)
    SHA256.feed hash_state (Cstruct.of_bytes new_chunk);                                (* update hash state *)
    let new_hash_and_chunks = (hash_state, if read_count > 0 then (new_chunk :: chunks) else chunks ) in
    if read_count < read_block_size then
      new_hash_and_chunks
    else begin
      acc_chunks ~acc:new_hash_and_chunks ~pos:(pos + read_count) ~file
    end in
  let acc_chunks_wrapper ~(file:Core.In_channel.t) : hash_state_and_chunks =
    acc_chunks ~acc:((SHA256.init ()), []) ~pos:0 ~file in

  let (final_hash_state, all_chunks) = In_channel.with_file ~binary:true filename ~f:(fun file -> acc_chunks_wrapper ~file) in
  let hash_bytes                     = Cstruct.to_string (SHA256.get final_hash_state) in
  ((Multihash.raw_hash_to_multihash ~hash_type:`SHA256 ~raw:hash_bytes), all_chunks)
;;

let test () : unit =
  let (hash, chunks) = file_hash_and_split ~ver:`V1 ~filename:"dummy_file" in
  Printf.printf "hash : %s\n" (Hex.hexdump_s ~print_row_numbers:false ~print_chars:false (Hex.of_string hash))
;;

test ();;