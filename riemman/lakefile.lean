/-
Copyright (c) 2026 Mustafa (isnowx). SPDX-License-Identifier: MIT
Contact: mustafa@snowgamestr.com
-/
import Lake
open Lake DSL

package «riemman» where

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.29.0-rc8"

@[default_target]
lean_lib Riemman where
  srcDir := "formal/Lean4"
