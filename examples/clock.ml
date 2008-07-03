open Mlpost
open Command
open Point

let fig =
  let pen = Pen.default ~tr:([Transform.scaled 10.0]) () in
  let circle = Path.transform [Transform.scaled (Num.cm 9.)] Path.fullcircle in
  let color = Color.blue in
  let time hr mn = 
    let m = (float_of_int (mn mod 60)) in
    let h = -.30. *. ((float_of_int (hr mod 12)) +. (m /. 60.)) in
      seq [Helpers.draw_simple_arrow ~color ~pen 
	     (pt (0.,0.)) (rotated h (pt (0.,Num.cm 2.)));
	   Helpers.draw_simple_arrow ~color ~pen 
	     (pt (0.,0.)) (rotated (-.6.*.m) (pt (0.,Num.cm 3.5)))]
  in
  let num i = 
    let tr = [Transform.rotated (float_of_int (-30*i))] in
      Picture.transform tr 
	(Picture.center (Picture.transform [Transform.scaled 2.0]
			   (Picture.tex (string_of_int i)))
	   (Point.pt (Num.cm 0., Num.cm 3.9))) in
  let pic = Picture.make (seq
    [draw ~color ~pen circle; 
     iter 1 12 (fun i -> draw_pic (num i));
     time 15 37;
     label (Picture.tex "sur une id\\'ee de Claude") (pt (0.,0.));
    ]) in
    [draw_pic (Picture.transform [Transform.scaled 0.3] pic)]
		 

(* let _ = Metapost.emit "clock" [fig] *)
