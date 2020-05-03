#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

requirements:
  ScatterFeatureRequirement: {}
  StepInputExpressionRequirement: {}

inputs:
  pangenome:
    label: GFA1 or GF2 format
    type: File
    # format: GFA1 or GFA2

  bin_widths:
    type: int[]
    default: [ 1, 4, 16, 64, 256, 1000, 4000, 16000]
    doc: width of each bin in basepairs along the graph vector

  cells_per_file:
    type: int
    default: 100
    doc: Cells per file on component_segmentation

steps:
  build_sparse_matrix_graph:
    label: Build the sparse matrix form of the gfa graph
    run: tools/odgi/odgi_build.cwl
    in:
      graph: pangenome
    out: [ sparse_graph_index ]

  # sort_paths:
  #   label: Sort paths by 1D sorting
  #   run: tools/odgi/odgi_sort.cwl
  #   in:
  #     pipeline_specification:
  #       default: "bSnSnS"
  #     sparse_graph_index: build_sparse_matrix_graph/sparse_graph_index
  #     sgd_use_paths:
  #       default: true
  #     sort_paths_max:
  #       default: true
  #   out: [ sorted_sparse_graph_index ]

  bin_paths:
    run: tools/odgi/odgi_bin.cwl
    in:
      sparse_graph_index: build_sparse_matrix_graph/sparse_graph_index
      bin_width: bin_widths
    scatter: bin_width
    out: [ bins, pangenome_sequence ]

  index_paths:
    label: Create path index
    run : tools/odgi/odgi_pathindex.cwl
    in:
      sparse_graph_index: build_sparse_matrix_graph/sparse_graph_index
    out: [ indexed_paths ] 

  segment_components:
    label: Run component segmentation
    run: tools/graph-genome-segmentation/component_segmentation.cwl
    in:
      bins: bin_paths/bins
      cells_per_file: cells_per_file
      pangenome_sequence:
        source: bin_paths/pangenome_sequence
        valueFrom: $(self[0])
        # the bin_paths step is scattered over the bin_width array, but always using the same sparse_graph_index
        # the pangenome_sequence that is extracted is exactly the same for the same sparse_graph_index
        # regardless of bin_width, so we take the first pangenome_sequence as input for this step
    out: [ colinear_components ]

outputs:
  indexed_paths:
    type: File
    outputSource: index_paths/indexed_paths

  colinear_components:
    type: File[]
    outputSource: segment_components/colinear_components
