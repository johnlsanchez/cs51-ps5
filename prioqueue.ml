(*
                         CS 51 Problem Set 5
                Modules, Functors, and Priority Queues
                           Priority Queues
 *)

 open Order ;;

 open Orderedcoll ;;
 
 (*======================================================================
 Priority queues
 
 A signature for a priority queue. See the problem set specification
 for more information about priority queues.
 
 IMPORTANT: In your implementations of priority queues, the MINIMUM
 valued element corresponds to the HIGHEST priority. For example, in an
 integer priority queue, the integer 4 has lower priority than the
 integer 2. In case of multiple elements with identical priority, the
 priority queue returns them according to the normal queue discipline,
 first-in-first-out.
 ......................................................................*)
 
 module type PRIOQUEUE =
 sig
   exception QueueEmpty
 
   (* The type of elements being stored in the priority queue *)
   type elt
 
   (* The queue itself (stores things of type `elt`) *)
   type queue
 
   (* Returns an empty queue *)
   val empty : queue
 
   (* Returns whether or not a queue is empty *)
   val is_empty : queue -> bool
 
   (* Returns a new queue with the element added *)
   val add : elt -> queue -> queue
 
   (* Returns a pair of the highest priority element in the argument
      queue and the queue with that element removed. In case there is
      more than one element with the same priority (that is, the
      elements compare `Equal`), returns the one that was added
      first. Can raise the `QueueEmpty` exception. *)
   val take : queue -> elt * queue
 
   (* Returns a string representation of the queue *)
   val to_string : queue -> string
 
   (* Runs invariant checks on the implementation of this binary tree.
      May raise `Assert_failure` exception *)
   val run_tests : unit -> unit
 
 end
 
 (*......................................................................
 Problem 2: Implementing ListQueue
 
 Implement a priority queue functor called `ListQueue`, which uses a
 simple list to store the queue elements in sorted order. Feel free to
 use anything from the `List` module.
 
 After you've implemented `ListQueue`, you'll want to test the functor
 by, say, generating an `IntString` priority queue and running the tests
 to make sure your implementation works.
 ......................................................................*)
 
 module ListQueue (C : COMPARABLE) : (PRIOQUEUE with type elt = C.t) =
   struct
     exception QueueEmpty
 
     type elt = C.t
 
     type queue = elt list
 
     let empty : queue = []
 
     let is_empty: queue -> bool =
       (=) [] 
 
     let rec add (e : elt) (q : queue) : queue =
       match q with 
       | [] -> [e]
       | hd :: tl -> 
         let comp = C.compare e hd in
         if comp = Less then e :: q
         else hd :: (add e tl)
 
     let take (q : queue) : elt * queue =
       match q with
       | [] -> raise QueueEmpty
       | hd :: tl -> hd, tl
 
     (* Should be exhaustive *)
     let test_is_empty () = 
       assert (is_empty empty);
       let x = C.generate () in 
       assert (is_empty (add x empty) = false);
       assert (is_empty (add x (add x empty)) = false);
       ()
     
     let test_add () = 
       let x = C.generate () in
       let t = add x empty in 
       assert (t = [x]);
       let y = C.generate_lt x in
       let t = add y t in
       assert (t = [y ; x]);
       let z = C.generate_gt x in
       let t = add z t in
       assert (t = [y ; x; z]);
       let t = add x t in
       assert (t = [y ; x; x; z]);
       ()
 
       let test_take () = 
         (* Successfully calls exception *)
         (* assert (take empty = (C.generate (), empty) ); *)
         let x = C.generate () in
         let t = add x empty in 
         assert (take t = (x, empty)) ;
         let y = C.generate_gt x in
         let t = add y t in 
         let z = C.generate_lt x in 
         let t = add z t in 
         assert (take t = (z, [x; y])) ;
         ()
 
     let run_tests () =
       test_is_empty ();
       test_add ();
       test_take ();
       ()
 
     (* IMPORTANT: Don't change the implementation of to_string. *)
     let to_string (q: queue) : string =
       let rec to_string' q =
         match q with
         | [] -> ""
         | [hd] -> (C.to_string hd)
         | hd :: tl -> (C.to_string hd) ^ ";" ^ (to_string' tl)
       in
       let qs = to_string' q in "[" ^ qs ^ "]"
   end
 
 (*......................................................................
 Problem 3: Implementing TreeQueue
 
 Now implement a functor TreeQueue that generates implementations of
 the priority queue signature PRIOQUEUE using a binary search tree.
 Luckily, you should be able to use *a lot* of your code from the work
 with `BinSTree`!
 
 If you run into problems implementing `TreeQueue`, you can at least
 add stub code for each of the values you need to implement so that
 this file will compile and will work with the unit testing
 code. That way you'll be able to submit the problem set so that it
 compiles cleanly.
 ......................................................................*)
 
 (* You'll want to uncomment this before working on this section! *)
 
 module TreeQueue (C : COMPARABLE) : (PRIOQUEUE with type elt = C.t) =
   struct
     exception QueueEmpty
 
     (* You can use the module T to access the functions defined in BinSTree,
        e.g. T.insert *)
     module T = (BinSTree(C) : (ORDERED_COLLECTION with type elt = C.t))
 
     (* Implement the remainder of the module. *)
     type elt = T.elt
 
     type queue = T.collection
 
     let empty : queue = T.empty 
 
     let is_empty (q : queue) : bool =
       q = T.empty
 
     let add: elt -> queue -> queue = 
       T.insert
 
     let take (q : queue) : elt * queue =
       let m = T.getmin q in
       m, T.delete m q
 
     let test_is_empty () =
       assert (is_empty empty);
       let x = C.generate () in
       let t = add x empty in
       assert (not (is_empty t));
       let t = add x t in 
       assert (not (is_empty t)); 
       ()
      
     let test_add () =
        let x = C.generate () in
        let t = add x empty in        
        assert (T.to_string t = "Branch (Leaf, [" ^ C.to_string x ^ "], Leaf)") ;
        let y = C.generate_gt x in
        let t = add y t in 
        assert (T.to_string t = 
          "Branch (Leaf, [" ^ C.to_string x ^ 
                          "], Branch (Leaf, [" ^ C.to_string y ^ "], Leaf))") ;
        let z = C.generate_lt x in 
        let t = add z t in
        assert (T.to_string t = 
          "Branch (Branch (Leaf, [" ^ C.to_string z ^ "], Leaf), [" ^ C.to_string x ^ 
                          "], Branch (Leaf, [" ^ C.to_string y ^ "], Leaf))") ;
        let t = add z t in
        assert (T.to_string t = 
          "Branch (Branch (Leaf, [" ^ C.to_string z ^ "; " ^ C.to_string z ^ 
                          "], Leaf), [" ^ C.to_string x ^ 
                          "], Branch (Leaf, [" ^ C.to_string y ^ "], Leaf))"); 
                          
                                                 
      ()
    
     let test_take () =
      let x = C.generate () in
      let t = add x empty in 
      assert (take t = (x, empty)) ;
      let y = C.generate_gt x in
      let t = add y t in 
      let z = C.generate_lt x in 
      let t = add z t in 
      let (ele, q) = take t in
      assert (ele = z) ;
      assert (T.to_string q = "Branch (Leaf, [" ^ C.to_string x ^ "], Branch (Leaf, [" ^ C.to_string y ^ "], Leaf))") ;
      let x1 = C.generate_lt x in
      let x2 = C.generate_lt x1 in
      let x3 = C.generate_lt x2 in
      let x4 = C.generate_lt x3 in   
      let after_ins = add x4 (add x3 (add x2 (add x1 (add x empty)))) in
      let t4, q = take after_ins in
      let t3, q = take q in
      let t2, q = take q in
      let t1, q = take q in
      assert (T.to_string q = "Branch (Leaf, [" ^ C.to_string x ^ "], Leaf)") ;
      let t, q = take q in
      assert ((t4, t3, t2, t1, t) = (x4, x3, x2, x1, x)) ;
      assert (q = empty) ;

      
      ()
 
     let run_tests () =
        test_is_empty ();
        test_add ();
        test_take ();
       ()
 
     let to_string (q: queue) : string =
       T.to_string q
 
 
   end
  
 
 (*......................................................................
 Problem 4: Implementing BinaryHeap
 
 Implement a priority queue using a binary heap. See the problem set
 writeup for more info.
 
 You should implement a min-heap, i.e., the top of your heap stores the
 smallest element in the entire heap (which will end up being the
 element with highest priority when the heap is iused as a priority
 queue).
 
 Note that, unlike for your tree and list implementations of priority
 queues, you do *not* need to worry about the order in which elements
 of equal priority are removed. Yes, this means it's not really a
 "queue", but it is easier to implement without that restriction.
 
 Be sure to read the problem set spec for hints and clarifications!
 
 Remember the invariants of the tree that make up your queue:
 
 1) A tree is ODD if its left subtree has 1 more node than its right
 subtree. It is EVEN if its left and right subtrees have the same
 number of nodes. The tree can never be in any other state. This is the
 WEAK invariant, and should never be false.
 
 2) All nodes in the subtrees of a node should be *greater* than (or
 equal to) the value of that node.  This, combined with the previous
 invariant, makes a STRONG invariant.  Any tree that a user passes in
 to your module and receives back from it should satisfy this
 invariant.  However, in the process of, say, adding a node to the
 tree, the tree may intermittently not satisfy the order invariant. If
 so, you *must* fix the tree before returning it to the user.  Fill in
 the rest of the module below!
 ......................................................................*)
    
 module BinaryHeap (C : COMPARABLE) : (PRIOQUEUE with type elt = C.t) =
   struct
 
     exception QueueEmpty
 
     type elt = C.t
 
     (* A node in the tree is either even or odd *)
     type balance = Even | Odd
 
     (* A tree either:
        1) is one single element,
        2) has one branch, where:
           the first element in the tuple is the element at this node,
           and the second element is the element down the branch,
        3) or has two branches (with the node being even or odd)
     *)
     type tree =
       | Leaf of elt
       | OneBranch of elt * elt
       | TwoBranch of balance * elt * tree * tree
 
     (* A queue is either empty or a tree *)
     type queue =
       | Empty
       | Tree of tree
 
     let empty = Empty
 
     (* to_string q -- Prints binary heap `q` as a string - nice for
        testing! *)
     let to_string (q: queue) =
       let rec to_string' (t: tree) =
         match t with
         | Leaf e1 -> "Leaf " ^ C.to_string e1
         | OneBranch(e1, e2) ->
                  "OneBranch (" ^ C.to_string e1 ^ ", "
                  ^ C.to_string e2 ^ ")"
         | TwoBranch(Odd, e1, t1, t2) ->
                  "TwoBranch (Odd, " ^ C.to_string e1 ^ ", "
                  ^ to_string' t1 ^ ", " ^ to_string' t2 ^ ")"
         | TwoBranch(Even, e1, t1, t2) ->
                  "TwoBranch (Even, " ^ C.to_string e1 ^ ", "
                  ^ to_string' t1 ^ ", " ^ to_string' t2 ^ ")"
       in
       match q with
       | Empty -> "Empty"
       | Tree t -> to_string' t
 
     (* is_empty q -- Predicate returns `true` if and only if `q` is
        an empty queue *)
     let is_empty : queue -> bool =
       (=) Empty
    
     let rec size (t : tree ) : int = 
      match t with
      | Leaf _ -> 1
      | OneBranch (_, _) -> 2
      | TwoBranch (_, _, left, right) -> 1 + size left + size right  ;;

     (* add e q -- Adds element `e` to the queue `q` *)
     let add (e : elt) (q : queue) : queue =
       
       (* Given a tree, where `e` will be inserted is deterministic based
          on the invariants. If we encounter a node in the tree where
          its value is greater than the element being inserted, then we
          place the new `elt` in that spot and propagate what used to be
          at that spot down toward where the new element would have
          been inserted *)
       let rec add_to_tree (e : elt) (t : tree) : tree =
         match t with
         (* If the tree is just a Leaf, then we end up with a OneBranch *)
         | Leaf e1 ->
            (match C.compare e e1 with
             | Equal
             | Greater -> OneBranch (e1, e)
             | Less -> OneBranch (e, e1))
 
         (* If the tree was a OneBranch, it will now be a TwoBranch *)
         | OneBranch (e1, e2) ->
            (match C.compare e e1 with
             | Equal
             | Greater -> TwoBranch (Even, e1, Leaf e2, Leaf e)
             | Less -> TwoBranch (Even, e, Leaf e2, Leaf e1))
 
         (* If the tree was even, then it will become an odd tree (and
            the element is inserted to the left *)
         | TwoBranch (Even, e1, t1, t2) ->
            (match C.compare e e1 with
             | Equal
             | Greater -> TwoBranch (Odd, e1, add_to_tree e t1, t2)
             | Less -> TwoBranch (Odd, e, add_to_tree e1 t1, t2))
 
         (* If the tree was odd, then it will become an even tree (and
            the element is inserted to the right *)
         | TwoBranch (Odd, e1, t1, t2) ->
            match C.compare e e1 with
            | Equal
            | Greater -> TwoBranch (Even, e1, t1, add_to_tree e t2)
            | Less -> TwoBranch (Even, e, t1, add_to_tree e1 t2)
       in
       
       (* If the queue is empty, then `e` is the only Leaf in the tree.
          Else, insert it into the proper location in the pre-existing
          tree *)
       match q with
       | Empty -> Tree (Leaf e)
       | Tree t -> Tree (add_to_tree e t)
 
     (*..................................................................
     get_top t -- Returns the top element of the tree `t` (i.e., just a
     single pattern match)
     ..................................................................*)
     let get_top (t : tree) : elt =
       match t with
       | Leaf x
       | OneBranch (x, _)
       | TwoBranch (_, x, _, _) -> x ;;
 
     (*..................................................................
     fix t -- Fixes trees whose top node is greater than its
     children. If fixing it results in a subtree where the node is
     greater than its children, then it (recursively) fixes this
     tree too. Resulting tree satisfies the strong invariant.
     ..................................................................*)
     let rec fix (t : tree) : tree =
 
       let tree_with_new_top old_tree ele =
         match old_tree with
         | Leaf _ -> Leaf ele
         | OneBranch (_, y) -> OneBranch (ele, y)
         | TwoBranch (bal, _, left, right) -> TwoBranch (bal, ele, left, right) in
 
       match t with
       | Leaf _ -> t
 
       | OneBranch (x, y) -> 
         if C.compare x y = Greater then OneBranch (y, x) else t
 
       | TwoBranch (bal, x, left, right) ->
         let left_ele, right_ele = get_top left, get_top right in
         if C.compare x left_ele <> Greater && C.compare x right_ele <> Greater then t
         else if C.compare left_ele right_ele = Greater then  
           TwoBranch (bal, right_ele, left, fix (tree_with_new_top right x)) 
         else
           TwoBranch (bal, left_ele, fix (tree_with_new_top left x), right)

      (* For testing purposes *)
      let rec is_fixed (t : tree) : bool =
        match t with
        | Leaf _ -> true
        | OneBranch (x, y) -> x <= y
        | TwoBranch (_, ele, left, right) -> 
          ele <= get_top left && ele <= get_top right && is_fixed left && is_fixed right 
           
      let is_even (t: tree) : bool =
        match t with 
        | Leaf _ -> false
        | OneBranch (_, _) -> false
        | TwoBranch (bal, _, _, _) -> bal = Even ;;

     let extract_tree (q : queue) : tree =
       match q with
       | Empty -> raise QueueEmpty
       | Tree t -> t
 
 
 
     
     
     (*..................................................................
     get_last t -- Takes a tree, and returns the item that was most
     recently inserted into that tree, as well as the queue that
     results from removing that element. Notice that a queue is
     returned. (This happens because removing an element from just a
     leaf would result in an empty case, which is captured by the queue
     type).
 
     By "item most recently inserted", we don't mean the most recently
     inserted *value*, but rather the newest node that was added to the
     bottom-level of the tree. If you follow the implementation of `add`
     carefully, you'll see that the newest value may end up somewhere
     in the middle of the tree, but there is always *some* value
     brought down into a new node at the bottom of the tree. *This* is
     the node that we want you to return.
     ..................................................................*)
     let rec get_last (t : tree) : elt * queue =
       match t with
       | Leaf x -> x, Empty
       | OneBranch (x, y) -> y, Tree (Leaf x)
       | TwoBranch (bal, x, left, right) ->
         if bal = Odd then
           let (last_ele, last_queue) = get_last left in
           last_ele, Tree (TwoBranch (Even, x, (extract_tree last_queue), right))
         else
           let (last_ele, last_queue) = get_last right in
           match last_queue with
             | Empty -> last_ele, Tree (OneBranch (x, get_top left))
             | Tree _ -> last_ele, Tree (TwoBranch (Odd, x, left, (extract_tree last_queue)))
 
 
     (*..................................................................
     take q -- Returns the hgiest priority element from `q` and the
     queue that ersults from deleting it. Implements the algorithm
     described in the writeup. You must finish this implementation, as
     well as the implementations of get_last and fix, which take uses.
     ..................................................................*)
     let take (q : queue) : elt * queue =
       match extract_tree q with
       (* If the tree is just a Leaf, then return the value of that
          leaf, and the new queue is now empty *)
       | Leaf e -> e, Empty
 
       (* If the tree is a OneBranch, then the new queue is just a
          Leaf *)
       | OneBranch (e1, e2) -> e1, Tree (Leaf e2)
 
       (* Removing an item from an even tree results in an odd
          tree. This implementation replaces the root node with the
          most recently inserted item, and then fixes the tree that
          results if it is violating the strong invariant *)
       | TwoBranch (Even, e, t1, t2) ->
          let (last, q2') = get_last t2 in
          (match q2' with
           (* If one branch of the tree was just a leaf, we now have
              just a OneBranch *)
           | Empty -> (e, Tree (fix (OneBranch (last, get_top t1))))
           | Tree t2' -> (e, Tree (fix (TwoBranch (Odd, last, t1, t2')))))
          (* Implement the odd case! *)
         | TwoBranch (Odd, e, t1, t2) ->
           let (last, q1') = get_last t1 in
           e, Tree (fix (TwoBranch (Even, last, extract_tree q1', t2)))
    
     let test_fix () = 
      let x = C.generate () in
      let x1 = C.generate_gt x in
      let x2 = C.generate_lt x in
      let x3 = C.generate_gt x in
      let x4 = C.generate_gt x1 in
      let t1 = OneBranch (x, x1) in
      let t2 = OneBranch (x2, x3) in
      let h = TwoBranch (Odd, x4, t1, t2) in
      assert (is_fixed h = false) ;
      assert (is_fixed (fix h) = true) ;
      (* Multistep propagation with two branches *)
      let y = C.generate () in
      let y1 = C.generate_lt y in
      let y2 = C.generate_lt y1 in
      let y3 = C.generate_lt y2 in
      let y4 = C.generate_lt y3 in
      let y5 = C.generate_lt y4 in
      let y6 = C.generate_lt y5 in
      let y7 = C.generate_lt y6 in
      let h1 = OneBranch (y5, y1) in
      let h2 = TwoBranch (Odd, y7, h1, Leaf y4) in
      let h3 = TwoBranch (Even, y6, Leaf y3, Leaf y2) in
      let h = TwoBranch (Odd, y, h2, h3) in
      assert (is_fixed (fix h) = true) ;
      ()

     let test_get_last () = 
      let x = C.generate () in
      let t = add x empty in
      assert (get_last (extract_tree t) = (x, Empty));
      let y = C.generate_gt x in 
      let t = add y t in
      assert (get_last (extract_tree t) = (y, Tree (Leaf x)));
      let z = C.generate_gt x in 
      let t = add z t in 
      assert (get_last (extract_tree t) = (z, Tree (OneBranch(x,y)))) ;
      let w = C.generate_gt y in
      let t = add w t in
      assert (get_last (extract_tree t) = (w, Tree (TwoBranch(Even, x, Leaf y, Leaf z)))) ;
      let m = C.generate_gt y in
      let t = add m t in
      assert (get_last (extract_tree t) = (w, Tree (TwoBranch(Odd, x, OneBranch (y,w), Leaf z)))) ;
      let n = C.generate_gt z in
      let t = add m t in
      assert (get_last (extract_tree t) = (n, Tree (TwoBranch(Even, x, OneBranch (y,w), OneBranch (z,m))))) ;
      let k = C.generate_gt y in
      let t = add m t in
      assert (get_last (extract_tree t) = (k, Tree (TwoBranch(Odd, x, TwoBranch (Even,y,Leaf w, Leaf n), OneBranch (z,m))))) ;
      ()


     let test_take () = 
      let y1 = C.generate () in
      let y2 = C.generate_lt y1 in
      let y3 = C.generate_lt y2 in
      let y4 = C.generate_lt y3 in
      let y5 = C.generate_lt y4 in
      let y6 = C.generate_lt y5 in
      let y7 = C.generate_lt y6 in
      let y8 = C.generate_lt y7 in
      let h1 = OneBranch (y5, y1) in
      let h2 = TwoBranch (Odd, y7, h1, Leaf y4) in
      let h3 = TwoBranch (Even, y6, Leaf y3, Leaf y2) in
      let h = TwoBranch (Odd, y8, h2, h3) in
      let ele, q = take (Tree h) in
      assert (ele = y8) ;
      assert (is_fixed (extract_tree q)) ;
      assert (is_even (extract_tree q)) ;
      assert (size (extract_tree q) = 7) ;
      let ele, q1 = take q in
      assert (ele = y7) ;
      assert (is_fixed (extract_tree q1)) ;
      assert (not (is_even (extract_tree q1))) ;
      assert (size (extract_tree q1) = 6) ;
      let ele, q2 = take q1 in
      assert (ele = y6) ;
      assert (is_fixed (extract_tree q2)) ;
      assert (is_even (extract_tree q2)) ;
      assert (size (extract_tree q2) = 5) ;
      let ele, q3 = take q2 in
      assert (ele = y5) ;
      assert (is_fixed (extract_tree q3)) ;
      assert (not (is_even (extract_tree q3))) ;
      assert (size (extract_tree q3) = 4) ;
      ()

     let run_tests () = 
      test_fix () ;
      test_get_last () ;
      test_take () ;;
      
   end
 
 (*......................................................................
 Now to actually use the priority queue implementations for something
 useful!
 
 Priority queues are very closely related to sorts. Remember that
 removal of elements from priority queues removes elements in highest
 priority to lowest priority order. So, if your priority for an element
 is directly related to the value of the element, then you should be
 able to come up with a simple way to use a priority queue for
 sorting...
 
 In OCaml 3.12 and above, modules can be turned into first-class
 values, and so can be passed to functions! Here, we're using that to
 avoid having to create a functor for sort. Creating the appropriate
 functor is a challenge problem :-)
 
 The following code is simply using the functors and passing in a
 COMPARABLE module for integers, resulting in priority queues tailored
 for ints.
 ......................................................................  *)
 
 module IntListQueue = (ListQueue(IntCompare) :
                          PRIOQUEUE with type elt = IntCompare.t)
 
 module IntHeapQueue = (BinaryHeap(IntCompare) :
                          PRIOQUEUE with type elt = IntCompare.t)
 
 module IntTreeQueue = (TreeQueue(IntCompare) :
                         PRIOQUEUE with type elt = IntCompare.t)
 
 (* Store the whole modules in these variables *)
 let list_module = (module IntListQueue :
                      PRIOQUEUE with type elt = IntCompare.t)
 let heap_module = (module IntHeapQueue :
                      PRIOQUEUE with type elt = IntCompare.t)
 let tree_module = (module IntTreeQueue :
                      PRIOQUEUE with type elt = IntCompare.t)
 
 
 (* Implementing sort using generic priority queues. *)
 let sort (m : (module PRIOQUEUE with type elt=IntCompare.t)) (lst : int list) =
   let module P = (val (m) : PRIOQUEUE with type elt = IntCompare.t) in
   let rec extractor pq lst =
     if P.is_empty pq then lst
     else
       let (x, pq') = P.take pq in
       extractor pq' (x::lst) in
   let pq = List.fold_right P.add lst P.empty in
   List.rev (extractor pq [])
 
 
 (* Now, we can pass in the modules into sort and get out different
    sorts. *)
 
 (* Sorting with a priority queue with an underlying heap
    implementation is equivalent to heap sort! *)
 let heapsort = sort heap_module ;;
 
 (* Sorting with a priority queue with your underlying tree
    implementation is *almost* equivalent to treesort; a real treesort
    relies on self-balancing binary search trees *)
 
 
 let treesort = sort tree_module ;;

 
 (* Sorting with a priority queue with an underlying unordered list
    implementation is equivalent to selection sort! If your
    implementation of ListQueue used ordered lists, then this is really
    insertion sort. *)
 let selectionsort = sort list_module
 
 (* You should test that these sorts all correctly work, and that lists
    are returned in non-decreasing order. *)

  let test_heapsort () = 
    assert (heapsort [] = []);
    assert (heapsort [1] = [1]);
    assert (heapsort [1;2] = [1;2]);
    assert (heapsort [2;1] = [1;2]);
    assert (heapsort [10;9;8;7;6;5;4;3;2;1;1;1] = [1;1;1;2;3;4;5;6;7;8;9;10]);
    assert (heapsort [333;222;111;1;1;2;2] = [1;1;2;2;111;222;333]);
    assert (heapsort [-1;-2;3;-5;-6] = [-6;-5;-2;-1;3]);
    () 
  ;;

  let test_treesort () = 
    assert (treesort [] = []);
    assert (treesort [1] = [1]);
    assert (treesort [1;2] = [1;2]);
    assert (treesort [2;1] = [1;2]);
    assert (treesort [10;9;8;7;6;5;4;3;2;1;1;1] = [1;1;1;2;3;4;5;6;7;8;9;10]);
    assert (treesort [333;222;111;1;1;2;2] = [1;1;2;2;111;222;333]);
    assert (treesort [-1;-2;3;-5;-6] = [-6;-5;-2;-1;3]);
    () ;;

  let test_selectionsort () = 
    assert (selectionsort [] = []);
    assert (selectionsort [1] = [1]);
    assert (selectionsort [1;2] = [1;2]);
    assert (selectionsort [2;1] = [1;2]);
    assert (selectionsort [10;9;8;7;6;5;4;3;2;1;1;1] = [1;1;1;2;3;4;5;6;7;8;9;10]);
    assert (selectionsort [333;222;111;1;1;2;2] = [1;1;2;2;111;222;333]);
    assert (selectionsort [-1;-2;3;-5;-6] = [-6;-5;-2;-1;3]);
    () ;;

test_heapsort () ;;
test_treesort () ;;
test_selectionsort () ;;  
 
 (*......................................................................
 Section 4: Challenge problem: Sort function
 
 A reminder: Challenge problems are for your karmic edification
 only. You should feel free to do these after you've done your best
 work on the primary part of the problem set.
 
 Above, we only allow for sorting on int lists. Write a functor that
 will take a COMPARABLE module as an argument, and allows for sorting
 on the type defined by that module. You should use your BinaryHeap
 module.
 
 As challenge problems go, this one is relatively easy, but you should
 still only attempt this once you are completely satisfied with the
 primary part of the problem set.
 ......................................................................*)
 
 (*......................................................................
 Section 5: Challenge problem: Benchmarking
 
 Now that you are learning about asymptotic complexity, try to write
 some functions to analyze the running time of the three different
 sorts. Record in a comment here the results of running each type of
 sort on lists of various sizes (you may find it useful to make a
 function to generate large lists).  Of course include your code for
 how you performed the measurements below.  Be convincing when
 establishing the algorithmic complexity of each sort.  See the CS51
 and Sys modules for functions related to keeping track of time
 ......................................................................*)
                          
 (*======================================================================
 Reflection on the problem set
 
      Please fill out the information about time spent and your
      reflection thereon in the file orderedcoll.ml.
  *)
 