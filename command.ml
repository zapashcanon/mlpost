(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Johannes Kanig, Stephane Lescuyer                       *)
(*  and Jean-Christophe Filliatre                                         *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2.1, with the special exception on linking            *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

open Misc
open Types
module T = Transform

type hposition = Types.hposition
type vposition = Types.vposition
type position = Types.position

type t = command

let label ?(pos=`Center) pic point = mkCLabel pic pos point
(* replace later *)
let dotlabel ?(pos=`Center) pic point = mkCDotLabel pic pos point

let draw ?color ?pen ?dashed t = 
  (* We don't use a default to avoid the output of 
     ... withcolor (0.00red+0.00green+0.00blue) withpen .... 
     for each command in the output file *)
    mkCDraw t color pen dashed

let draw_arrow ?color ?pen ?dashed t = 
  mkCDrawArrow t color pen dashed

let fill ?color t = mkCFill t color

let seq l = mkCSeq l

let iter from until f = 
  let l = Misc.fold_from_to (fun acc i -> f i :: acc) [] from until in
  seq (List.rev l)

let draw_pic p = mkCDrawPic p

let append c1 c2 = mkCSeq [c1; c2]
let (++) = append

let externalimage filename spec = mkCExternalImage filename spec

(* syntactic sugar *)

let iterl f l = seq (List.map f l)

let nop = mkCSeq []
