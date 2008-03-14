(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Johannes Kanig, Stephane Lescuyer                       *)
(*  and Jean-Christophe Filliatre                                         *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2, with the special exception on linking              *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

open Command
open Helpers

type node_style = Circle | Rect

type t = N of node_style option * Color.t option * string * t list

let leaf ?style ?fill s = N (style, fill, s, [])
let node ?style ?fill s l = N (style, fill, s, l)
let bin  ?style ?fill s x y = N (style, fill, s, [x; y])

let rec width cs = function
  | [] -> 0.
  | [w, _] -> w
  | (w, _) :: l -> w +. cs +. width cs l

let box style p pic = match style with
  | Circle -> Box.circle p pic
  | Rect -> Box.rect p pic

type arrow_style = Directed | Undirected

type edge_style = Straight | Curve | Square | HalfSquare

let arc astyle estyle ?stroke ?pen (b1,(x1,y1)) (b2,(x2,y2)) =
  let boxdraw, linedraw  = match astyle with 
    | Directed -> 
	box_arrow ?color:stroke ?pen, draw_arrow ?color:stroke ?pen
    | Undirected -> 
	box_line ?color:stroke ?pen, draw ?color:stroke ?pen 
  in
    match estyle with
      | Straight -> boxdraw ~style:Path.JLine b1 b2
      | Curve -> 
	  let p1, p2 = Box.center b1, Box.center b2 in
	  let corner = Point.p (x2-.(x2-.x1)/.4.,(y1+.y2)/.2.) in
	  let p = SimplePath.pathk ~style:Path.JCurve
	    [Path.NoDir, p1, Path.Vec (Point.sub corner p1); 
	     Path.NoDir, corner, Path.NoDir; 
	     Path.Vec (Point.sub p2 corner), p2, Path.NoDir] in
	  let parrow = 
	    Path.cut_after (Path.bpath b2) (Path.cut_before (Path.bpath b1) p)
	  in
	    linedraw parrow
      | Square -> 
	  let corner = Point.p (x2,y1) in
	  let p = SimplePath.pathp ~style:Path.JLine 
	    [Box.center b1; corner; Box.center b2] in
	  let parrow = 
	    Path.cut_after (Path.bpath b2) (Path.cut_before (Path.bpath b1) p) 
	  in
	    linedraw parrow
      | HalfSquare -> 
	  let m = (y1+.y2)/.2. in
	  let corner1, corner2 = Point.p (x1,m), Point.p (x2,m) in
	  let p = SimplePath.pathp ~style:Path.JLine 
	    [Box.center b1; corner1; corner2; Box.center b2] in
	  let parrow = 
	    Path.cut_after (Path.bpath b2) (Path.cut_before (Path.bpath b1) p) 
	  in
	    linedraw parrow

let draw ?(scale=Num.cm) 
    ?(node_style=Circle) ?(arrow_style=Directed) ?(edge_style=Straight)
    ?fill ?stroke ?pen
    ?(ls=1.0) ?(nw=0.5) ?(cs=0.2) t =
  let point x y = Point.p (scale x, scale y) in
  (* tree -> float * (float -> float -> box * figure) *)
  let rec draw (N (nstyle, nfill, s, l)) =
    let l = List.map draw l in
    let w = max nw (width cs l) in
    w,
    fun x y -> 
      let node_style = match nstyle with None -> node_style | Some s -> s in
      let fill = match nfill with None -> fill | Some _ -> nfill in
      let (b,_) as bx = 
	box node_style (point x y) (Picture.tex s), (scale x, scale y) in
      let x = ref (x -. w /. 2.) in
      b, 
      draw_box ?fill b :: 
	List.map 
	(fun (wc,fc) -> 
	   let x',y' = (!x +. wc /. 2.), (y -. ls) in
	   let b',fig = fc x' y' in
	   let bx' = b', (scale x', scale y') in
	   x := !x +. wc +. cs;
	   append (seq fig) (arc ?stroke ?pen arrow_style edge_style bx bx')
	) l
  in
  let _,f = draw t in
  snd (f 0. 0.)


  
