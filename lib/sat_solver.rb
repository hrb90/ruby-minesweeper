require 'minisat'
require_relative 'grid_helper'

class MinesweeperSatSolver
  include GridHelper

  # The solver assumes that every flag is actually on a bomb
  # It is also more powerful if flags are included in the grid
  def initialize(grid)
    @solver = MiniSat::Solver.new
    @grid_vars = []
    grid.each do |row|
      @grid_vars << Array.new(row.length) { @solver.new_var }
    end
    add_constraints_from_grid(grid)
  end

  def solve(i, j, bomb = true)
    var = bomb ? @grid_vars[i][j] : -@grid_vars[i][j]
    @solver.solve(var)
  end

  private

  def add_constraints_from_grid(grid)
    grid.each_with_index do |row, i|
      row.each_with_index do |tile, j|
        if is_number?(tile)
          add_to_solver(grid, i, j)
        end
      end
    end
  end

  def add_to_solver(grid, i, j)
    neighbors = get_neighbors(grid, i, j)
    if all_neighbors_bombs?(grid, i, j)
      neighbors.each do |v, pos|
        next unless v == :o
        x,y = pos
        @solver << [@grid_vars[x][y]]
      end
    else
      num_flags = neighbors.count { |v, _| v == :f }
      neighbor_vars = neighbors.select { |v, _| v == :o }.map do |_, pos|
        x, y = pos
        @grid_vars[x][y]
      end
      add_exact_constraint(neighbor_vars, grid[i][j] - num_flags)
    end
  end

  # Adds the constraint to the solver that exactly num_bombs of vars must be true
  def add_exact_constraint(vars, num_bombs)
    # every combination of vars.length - num_bombs + 1 vars has a bomb
    vars.combination(vars.length - num_bombs + 1).each do |clause_vars|
      @solver << clause_vars
    end
    # every combination of num_bombs + 1 vars has a non-bomb
    vars.combination(num_bombs + 1).each do |clause_vars|
      @solver << clause_vars.map { |x| -x }
    end
  end

end
