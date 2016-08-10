---
title: Design Recipe
author: Junyang
layout: post
permalink: /Design-Recipe/
tags: 
  - OCaml
---
{% include JB/setup %}

In this article, I will explain the design recipe for writing functions over typed data and present a simple example.

<!--more-->

1. Write a **data definition** to identify the types of all fields in both the input and output structures.
2. Provide **example** of the data the procedure will process.
3. Specify the procedure's **type signature** to indicate the types that procedure consumes and produces.
4. Write down **call structure**, i.e. write down function name, argument names and argument&result types.
5. Provide some **test cases** that exemplify the procedure's operation in comments.
6. **Deconstruct input** data structures -- the argument types suggests how to do it. 
7. **Build new output** values -- the result type suggests how to do it.
8. **Clean up** by identifying repeated patterns -- define and reuse helper functions, make code elegant and easy to read.

**Example**: Computing the distance between two points.

> Step 1: Data definition
	- type point = float * float.

> Step 2: Data example
	- input example (3.0, 4.0), (0.0, 0.0); output example 1.0.

> Step 3: Type signature
	- input type is point; output type is float.

> Step 4: Call structure
	- let distance (p1:point) (p2:point) : float = ... ;;

> Step 5: Test cases 
	- assert (distance (0.0, 0.0) (3.0, 4.0) = 5.0);;
	- assert (distance (0.0, 1,0) (1.0, 0.0) = sqrt(1.0 + 1.0));;
 
> Step 6: Deconstruct
	- let (x1,y1) = p1 in
	- let (x2,y2) = p2 in
	- ...

> Step 7: Construct
	- sqrt ((x2 -. x1) *. (x2 -. x1)) +. (y2 -. y1) *. (y2 -. y1));;

> Step 8: Clean up
	- let square x = x *. x in
	- ...
	- sqrt (square (x2 -. x1) +. square (y2 -. y1));;

- **The final code**

		- type point = float * float

		- let distance (p1:point) (p2:point) : float =
		- let square x = x *. x in
		- let (x1,y1) = p1 in
		- let (x2,y2) = p2 in
		- sqrt (square (x2 -. x1) +. square (y2 -. y1))
		;;

		- assert (distance (0.0, 0.0) (3.0, 4.0) = 5.0);;
		- assert (distance (0.0, 1,0) (1.0, 0.0) = sqrt(1.0 + 1.0));;



