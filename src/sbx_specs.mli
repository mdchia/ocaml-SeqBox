open Stdint

type version = [ `V1 | `V2 | `V3 ]

module Parser : sig
  val ver_p : version Angstrom.t
end

val sbx_file_uid_len    : int

val sbx_signature       : bytes

val sbx_header_size     : int

val ver_to_int          : version -> int

val ver_to_uint8        : version -> uint8

val ver_to_uint16       : version -> uint16

val ver_to_bytes        : version -> bytes

val ver_to_block_size   : version -> int

val ver_to_data_size    : version -> int

val string_to_ver       : string  -> (version, string) result
