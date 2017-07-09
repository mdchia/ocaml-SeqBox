# ocaml-SeqBox
Implementation of SeqBox in OCaml

The original pharsing was "Port of SeqBox to OCaml", but since no direct porting/translation was actually done due to the differences between Python 3(implementation language of SeqBox) and OCaml, which also force the architecture and design of this software(ocaml-SeqBox) to be independently developed, thus this is only an implementation(not a port or translation) of SeqBox according to its technical specifications.
This is mainly to address the different licenses being used(SeqBox was using AGPL 3.0 at the time of writing while this project uses 3-Clause BSD license).

Official SeqBox Repo - https://github.com/MarcoPon/SeqBox
                                                                                       
Table of Contents
=================

   * [ocaml-SeqBox](#ocaml-seqbox)
      * [Notes](#notes)                                                                
      * [Possibly useful additional features of ocaml-SeqBox(possibly not yet in official SeqBox)](#possibly-useful-additional-features-of-ocaml-seqboxpossibly-not-yet-in-official-seqbox)                                                                          
      * [Technical Specification](#technical-specification)                            
         * [Common blocks header:](#common-blocks-header)                              
         * [Block 0](#block-0)                                                         
         * [Blocks &gt; 0 &amp; &lt; last:](#blocks--0---last)                         
         * [Blocks == last:](#blocks--last)                                            
         * [Versions:](#versions)
         * [Metadata encoding:](#metadata-encoding)
            * [IDs](#ids)
            * [Features currently NOT planned to be implemented](#features-currently-not-planned-to-be-implemented)
      * [Index of source code](#index-of-source-code)
      * [Progress Report](#progress-report)
      * [Specification of ocaml-SeqBox](#specification-of-ocaml-seqbox)
            * [Encoding workflow](#encoding-workflow)
            * [Decoding workflow](#decoding-workflow)
            * [To successfully encode a file](#to-successfully-encode-a-file)
            * [To successfully decode a sbx container](#to-successfully-decode-a-sbx-container)
            * [Handling of duplicate metadata/data blocks](#handling-of-duplicate-metadatadata-blocks)
            * [Handling of duplicate metadata in metadata block given the block is valid](#handling-of-duplicate-metadata-in-metadata-block-given-the-block-is-valid)
      * [License](#license)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

## Notes
~~CRC-CCITT implementation is translated from libcrc (https://github.com/lammertb/libcrc) using a copy retrieved on 2017-06-27~~
  - ~~See License section for details on licensing~~

CRC-CCITT is currently implemented via FFI and links to the static object files compiled from libcrc (https://github.com/lammertb/libcrc)
  - See crcccitt_wrap.ml, crcccitt_wrap.mli for the FFI bindings
  - See crcccitt.c, checksum.h for libcrc source used(crcccitt.c is slightly modified, modification is under same license used by libcrc)

Exact behaviours in non-standard cases are not specified in official SeqBox technical specification
  - See Specification of ocaml-SeqBox section for details on how ocaml-SeqBox behaves(if you care about undefined behaviour those sort of things)

## Possibly useful additional features of ocaml-SeqBox(possibly not yet in official SeqBox)
  - Allows random ordering in sbx container
    - This also means block corruption will not stop the decoding process
  - Allows duplicate metadata/data blocks to exist within one sbx container
    - This means you can concatenate multiple copies of sbx container together directly to increase chance of recovery in case of corruption

## Technical Specification
The following specification is copied directly from the official specification with slight modification(version 2, 3 are stated excplicitly as not implemented yet).

Also see section "Features currently NOT planned to be implemented" for features ocaml-SeqBox is probably not going to have

Byte order: Big Endian
### Common blocks header:

| pos | to pos | size | desc                                |
|---- | ---    | ---- | ----------------------------------- |
|  0  |      2 |   3  | Recoverable Block signature = 'SBx' |
|  3  |      3 |   1  | Version byte |
|  4  |      5 |   2  | CRC-16-CCITT of the rest of the block (Version is used as starting value) |
|  6  |     11 |   6  | file UID                            |
| 12  |     15 |   4  | Block sequence number               |

### Block 0

| pos | to pos   | size | desc             |
|---- | -------- | ---- | ---------------- |
| 16  | n        | var  | encoded metadata |
|  n+1| blockend | var  | padding (0x1a)   |

### Blocks > 0 & < last:

| pos | to pos   | size | desc             |
|---- | -------- | ---- | ---------------- |
| 16  | blockend | var  | data             |

### Blocks == last:

| pos | to pos   | size | desc             |
|---- | -------- | ---- | ---------------- |
| 16  | n        | var  | data             |
| n+1 | blockend | var  | padding (0x1a)   |

### Versions:
N.B. Current versions differs only by blocksize.

| ver | blocksize | note    |
|---- | --------- | ------- |
|  1  | 512       | default |
|  2  | 128       | NOT IMPLEMENTED (yet) |
|  3  | 4096      | NOT IMPLEMENTED (yet) |

### Metadata encoding:

| Bytes | Field | 
| ----- | ----- |
|    3  | ID    |
|    1  | Len   |
|    n  | Data  |

#### IDs

| ID | Desc |
| --- | --- |
| FNM | filename (utf-8) |
| SNM | sbx filename (utf-8) |
| FSZ | filesize (8 bytes) |
| FDT | date & time (8 bytes, seconds since epoch) |
| SDT | sbx date & time (8 bytes) |
| HSH | crypto hash (SHA256, using [Multihash](http://multiformats.io) protocol) |
| PID | parent UID (*not used at the moment*)|

#### Features currently NOT planned to be implemented
  - Data hiding (XOR encoding/decoding in official seqbox)
    - Provides neither sufficiently strong encryption nor sufficient stealth for any serious attempt to hide/secure data
    - You should use the appropriate tools for encryption
  - ~~Version 2 of SBX block~~
    - ~~Current set of metadata cannot fit into a 128 bytes block size~~
    - ~~No way to extend storage of metadata block in current specs~~
    - ~~128 bytes block is likely only going to be useful for archaic systems~~

## Index of source code
 
**Sbx_block module (sbx_block.ml, sbx_block.mli)**
  - Single SBX block construction/access, encoding to bytes and decoding from bytes
  - Submodules
    - Header
    - Metadata
    - Block
    
**Stream_file (stream_file.ml, stream_file.mli)**
  - Provides framework for streamed processing of files
  - Abstracts away low-level file interaction, allows other modules to only construct "processor" to be run by the framework
    - Processor is a function that only deals with input and/or output channel
    
**Encode module (encode.ml, encode.mli)**
  - Encode file (and directly output into another file)
  - Relies on processor framework in Stream_file
  
**Decode module (decode.ml, decode.mli)**
  - Decode file (and directly output into another file)
  - Relies on processor framework in Stream_file

## Progress Report
  - Single SBX block encoding - done (Sbx_block module)
  - Single SBX block decoding - done (Sbx_block module)
  - Streamed processing framework - done (Streamed_file module)
  - Streamed file encoding - done (Encode module)
  - Streamed file decoding - done (Decode module)
  - Profiling and optimization of encoding - done
    - Result : CRC-CCITT implementation causes major slowdown
  - Profiling and optimization of decoding - done
    - Result : CRC-CCITT implementation causes major slowdown
  - Replace CRC-CCITT implementation with a more efficient one(or create FFI to libcrc) - done
    - CRC-CCITT is implemented via FFI to libcrc
  - Commandline interface for encoding and decoding - in progress
  - Further profiling and optimization of encoding - not started
  - Further profiling and optimization of decoding - not started
  - Scan mode - not started
  - Recovery mode - not started
  - Commandline options for scanning and recovery - not started

## Specification of ocaml-SeqBox
#### Encoding workflow
  1. If metadata is enabled, the following file metadata are gathered from file or retrieved from user input : file name, sbx file name, file size, file last modification time, encoding start time
  2. If metadata is enabled, then a partial metadata block is written into the output file as filler
    - The written metadata block is valid, but does not contain the actual file hash, a filler pattern of 0x00 is used in place of the hash part of the multihash(the header and length indicator of multihash are still valid)
  3. Load version specific data sized chunk one at a time from input file to encode and output(and if metadata is enabled, SHA256 hash state is updated as well)
    - data size = block size - header size (e.g. version 1 has data size of 512 - 16 = 496)
  4. If metadata is enabled, the encoder seeks back to starting position of output file and overwrites the metadata block with one that contains the SHA256 hash

#### Decoding workflow
Metadata block is valid if and only if
  - Header can be parsed
  - All metadata fields(duplicated or not) can be parsed successfully
  - All remaining space is filled with 0x1A pattern
  - version(specifically alignment/block size) matches reference block(see below)
  - CRC-CCITT is correct

Data block is valid if and only if
  - Header can be parsed
  - version and uid matches reference block(see below)
  - CRC-CCITT is correct

  1. A reference block is retrieved first(which is used for guidance on alignment, version, and uid)
    - the entire sbx container is scanned using alignment of 512 bytes, 512 is used as it is the largest common divisor of 512(block size for version 1) and 4096(block size for version 3)
    - if there is any valid metadata block in sbx container, then the first one will be used as reference block
    - else the first valid data block will be used as reference block
  2. Scan for valid blocks from start of sbx container to decode and output using reference block's block size as alignment
    - if a block is invalid, nothing is done
    - if a block is valid, and is a metadata block, nothing is done
    - if a block is valid, and is a data block, then it will be written to the writepos at output file, where writepos = (sequence number - 1) * block size of reference block in bytes
  3. If possible, truncate output file to remove data padding done for the last block during encoding
    - if reference block is a metadata block, and contains file size field, then the output file will be truncated to that file size
    - otherwise nothing is done
  4. If possible, report/record if the SHA256 hash of decoded file matches the recorded hash during encoding
    - if reference block is a metadata block, and contains the hash field, then the output file will be hashed to check against the recorded hash
      - output file will not be deleted even if hash does not match
    - otherwise nothing is done

#### To successfully encode a file
  - File size must be within threshold
    - For version 1, that means  496 * 2^32 - 1 =  ~1.9375 TiB, where 496 is data size, obtained via 512(block size) - 16(header size)
    - For version 2, that means  112 * 2^32 - 1 =  ~0.4375 TiB, where 112 is data size, obtained via 128(block size) - 16(header size)
    - For version 3, that means 4080 * 2^32 - 1 = ~15.9375 TiB, where 4080 is data size, obtained via 4096(block size) - 16(header size)

#### To successfully decode a sbx container
  - At least one valid data block for each position must exist
  - If data padding was done for the last block, then at least one valid metadata block must exist for truncation of the output file to happen

#### Handling of duplicate metadata/data blocks
  - First valid metadata block will be used(if exists)
  - For all other data blocks, the last seen valid data block will be used for a given sequence number

#### Handling of duplicate metadata in metadata block given the block is valid
  - For a given ID, only the first occurance of the metadata will be used
    e.g. if there are two FNM metadata fields in the metadata block, only the first (in terms of byte order) will be used

## License
The following files directly from libcrc(with slight modification) are under the same MIT license used by libcrc
  - crcccitt.c
  - checksum.h
  
~~The following files translated/ported from libcrc are under the MIT license as used by libcrc as well~~
  - ~~crcccitt.ml~~
  - ~~crcccitt.mli~~

All remaining files are distributed under the 3-Clause BSD license as stated in the LICENSE file
