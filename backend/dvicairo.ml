(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Johannes Kanig, Stephane Lescuyer                       *)
(*  Jean-Christophe Filliatre, Romain Bardou and Francois Bobot           *)
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

open Format
open Dviinterp



type multi_page_pic = {pic :Cairo.t;
            new_page : unit -> unit;
             x_origin : float;
             y_origin : float
           }

let conversion = 0.3937 *. 72.
let point_of_cm cm = conversion *. cm

let debug = ref false
let specials = ref false
let info = ref false

module Cairo_device : dev with type arg = multi_page_pic with type cooked
  = unit =
struct
  type arg = multi_page_pic
  type t = { arg : arg;
             doc : Dvi.t}
             (*fonts :(string,Cairo_ft.font_face * Cairo_ft.ft_face) 
               Hashtbl.t*)
  type cooked = unit

  let ft = Cairo_ft.init_freetype ()

  let fonts_known = Hashtbl.create 30

  let find_font font = 
    let font_name = Fonts.tex_name font in
    try Hashtbl.find fonts_known font_name
    with Not_found ->
      if !debug then printf "Cairo : Loading font %s@." font_name;
      let filename = Fonts.glyphs_filename font in
      if !debug then printf "Trying to find font at %s...@." filename;
      let face = Cairo_ft.new_face ft filename in
      let f =Cairo_ft.font_face_create_for_ft_face face 0,face in
      Hashtbl.add fonts_known font_name f;f

  let clean_up () = 
    Hashtbl.iter (fun _ (_,x) -> Cairo_ft.done_face x) fonts_known;
    Cairo_ft.done_freetype ft

  let new_document arg doc = 
    let first_page = ref true in
    {arg = {arg with new_page = 
         (fun () -> if !first_page then first_page := false 
          else arg.new_page ());
         x_origin = point_of_cm arg.x_origin;
         y_origin = point_of_cm arg.y_origin};
     doc = doc}

  let new_page s = 
    s.arg.new_page ()

  let set_source_color pic = function
    | RGB(r,g,b) -> 
        if !debug then
          printf "Use color RGB (%f,%f,%f)@." r g b;
        Cairo.set_source_rgb pic r g b
    | Gray(g) -> 
        if !debug then
          printf "Use color Gray (%f)@." g;
        Cairo.set_source_rgb pic g g g
    | CMYK _ -> failwith "dvicairo : I don't know how to convert CMYK\
 to RGB and cairo doesn't support it"
    | HSB _ -> failwith "dvicairo : I'm lazy I haven't written this conversion"
        (* http://en.wikipedia.org/wiki/HSL_and_HSV#Conversion_from_HSV_to_RGB
        and in color.ml*)


  let fill_rect s dinfo x1 y1 w h = 
    let x1 = point_of_cm x1 +. s.arg.x_origin
    and y1 = point_of_cm y1 +. s.arg.y_origin
    and w = point_of_cm w
    and h = point_of_cm h in
    if !debug then
      printf "Draw a rectangle in (%f,%f) with w=%f h=%f@." x1 y1 w h;
    Cairo.save s.arg.pic;
    set_source_color s.arg.pic dinfo.Dviinterp.color;
    Cairo.rectangle s.arg.pic x1 y1 w h;
    Cairo.fill s.arg.pic;
    Cairo.restore s.arg.pic

  let draw_char s dinfo font char x y = 
    let f = fst (find_font font) in
    let char = Fonts.glyphs_enc font (Int32.to_int char)
    and x = point_of_cm x +. s.arg.x_origin
    and y = point_of_cm y +. s.arg.y_origin
    and ratio = Fonts.scale font conversion in
    if !debug then begin
      let name = Fonts.tex_name font in
      try
        printf "Draw the char %i(%c) of %s in (%f,%f) x%f@." 
          char (Char.chr char) name x y ratio;
      with _ -> 
        printf "Draw the char %i of %s  in (%f,%f) x%f@." char name x y ratio
    end;
        
    Cairo.save s.arg.pic;
    set_source_color s.arg.pic dinfo.Dviinterp.color;
    Cairo.set_font_face s.arg.pic f ;
    Cairo.set_font_size s.arg.pic ratio;
    (* slant and extend *)
    (match Fonts.slant font with
      | Some a when !info -> 
          printf "slant of %f not used for %s@." a (Fonts.tex_name font)
      | Some _ | None -> ());
    (match Fonts.extend font with
      | Some a when !info -> 
          printf "extend of %f not used for %s@." a (Fonts.tex_name font)
      | Some _ | None -> ());
    Cairo.show_glyphs s.arg.pic 
      [|{Cairo.index = char;
         Cairo.glyph_x = x;
         Cairo.glyph_y = y}|];
    Cairo.stroke s.arg.pic;
    Cairo.restore s.arg.pic

  let specials s info xxx x y =
    if !debug || !specials then
      printf "specials : \"%s\" at (%f,%f)@." xxx x y

  let end_document s = 
    ()
end
