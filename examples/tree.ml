open Mlpost
open Box
open Tree
let sprintf = Format.sprintf

(*parse <<togglescript>> *)

(*parse <<tree1 *)
let tree1 =
  let node s = node (tex s) in
  let leaf s = leaf (tex s) in
  draw (node "1" [node "2" [leaf "4"; leaf "5"]; 
		   node "3" [leaf "6"; leaf "7"]])
(*parse >> <<tree2 *)
let tree2 =
  let leaf s = leaf  (tex ~style:Rect s) in
  let node s = node ~arrow_style:Undirected (tex ~style:Rect s) in
  draw 
     (node "1" [node "2" [leaf "4"; leaf "5"]; 
		node "3" [leaf "6"; leaf "7"]])

(*parse >> <<tree3 *)
let tree3 =
  let node s = node  ~arrow_style:Undirected ~edge_style:Curve (tex s) in
  let leaf s = leaf (tex s) in
  draw     (node "1" [node "2" [leaf "4"; leaf "5"]; 
		node "3" [leaf "6"; leaf "7"]])

(*parse >> <<tree4 *)
let tree4 =
  let node s = node ~arrow_style:Undirected ~edge_style:Square (tex s) in
  let leaf s = leaf (tex s) in
  draw 
     (node "1" [node "2" [leaf "4"; leaf "5"]; 
		node "3" [leaf "6"; leaf "7"]])

(*parse >> <<tree5 *)
let tree5 =
  let node s = node  ~arrow_style:Undirected ~edge_style:HalfSquare (tex s) in
  let leaf s = leaf (tex s) in
  draw     
    (node "1" [node "2" [leaf "4"; leaf "5"]; 
		node "3" [leaf "6"; leaf "7"]])

(*parse >> <<tree6 *)
let tree6 =
  let node s = node ~edge_style:HalfSquare (tex s) in
  let leaf s = leaf (tex s) in
  draw 
     (node "1" [node "2" [leaf "4"; leaf "5"]; 
		node "3" [leaf "6"; leaf "7"]])
(*parse >> <<tree7 *)
let tree7 =
  let node s = node ~arrow_style:Undirected ~edge_style:HalfSquare (Box.tex s) in
  let leaf s = leaf (Box.tex s) in
  draw 
     (node "1" [node "2" [node "3" [leaf "4"]; leaf "5"]; 
		node "3" [node "6" [leaf "8"; node "6" [leaf "8"; leaf "9"]]; 
			  node "7" [leaf "10"]]])
(*parse >> <<tree8 *)
let stern_brocot h =
  let frac (a,b) = tex (sprintf "$\\frac{%d}{%d}$" a b) in
  let rec make ((a,b) as lo) ((c,d) as hi) h =
    let r = a+c, b+d in
    if h = 1 then
      leaf (frac r)
    else
      node ~arrow_style:Undirected (frac r) [make lo r (h-1); make r hi (h-1)]
  in
  make (0,1) (1,0) h

let tree8 = draw (stern_brocot 5)
(*parse >> <<tree9 *)

let texint n = tex (sprintf "$F_{%d}$" n)
let rec fib = function
  | 0 | 1 as n -> leaf (texint n)
  | n -> node ~arrow_style:Undirected (texint n) [fib (n-1); fib (n-2)]

let tree9 = draw (fib 5)

(*parse >> <<tree10 *)
type 'a t = | Node of 'a * 'a t list

let rec bin = function
  | 0 -> Node (0, [])
  | n -> 
      let (Node (_,l) as t) = bin (n-1) in
      Node (n, t :: l)

let rec trans (Node (n,l)) = 
  node ~arrow_style:Undirected (tex (sprintf "${2^{%d}}$" n)) (List.map trans l)

let tree10 = draw (trans (bin 4))
(*parse >> <<tree11 *)
open Tree.Simple
open Num

let point = 
  let pen = Pen.scale (bp 2.) (Pen.circle) in
  Box.pic ~dx:zero ~dy:zero (Path.draw ~pen (Path.pathp [Point.origin]))

(* We use the type defined in the previous example *) 
let rec bin = function
  | 0 -> Node (point, [])
  | n -> 
      let (Node (p,l) as t) = bin (n-1) in
      Node (p, t :: l)

let rec to_tree (Node (b,l)) = 
  node ~arrow_style:Undirected ~valign:`Right b (List.map to_tree l)


let tree11 = draw (to_tree (bin 5))
(*parse >> *)

let _ = 
  List.iter (fun (name,fig) -> Metapost.emit name fig)
  [ "tree1", tree1;
    "tree2", tree2;
    "tree3", tree3;
    "tree4", tree4;
    "tree5", tree5;
    "tree6", tree6;
    "tree7", tree7;
    "tree8", tree8;
    "tree9", tree9;
    "tree10", tree10;
    "tree11", tree11;
  ]
