#!/bin/bash

GPU=0 # Set to whatever GPU you want to use

# First: process data

# Make sure to replace this with the directory containing the data files
IN_DIR='data/motion/raw/35/'
DATA_PATH='data/motion/processed/35'
mkdir -p $DATA_PATH
# python -u locs/datasets/cmu_motion_data.py --data_path $IN_DIR --out_path $DATA_PATH

BASE_RESULTS_DIR="results/motion_35"

for SEED in {1..5}
do
    MODEL_TYPE="dnri"
    EXPERIMENT_EXT='_release'
    WORKING_DIR="${TMP_BASE_RESULTS_DIR}/${MODEL_TYPE}${EXPERIMENT_EXT}/seed_${SEED}/"
    ENCODER_ARGS="--encoder_hidden 256 --encoder_mlp_num_layers 3 --encoder_mlp_hidden 128 --encoder_rnn_hidden 64"
    DECODER_ARGS="--decoder_hidden 256"
    HIDDEN_ARGS="--rnn_hidden 64"
    PRIOR_ARGS="--use_learned_prior --prior_num_layers 3 --prior_hidden_size 128"
    MODEL_ARGS="--model_type $MODEL_TYPE --graph_type dynamic --skip_first --num_edge_types 4 $ENCODER_ARGS $DECODER_ARGS $HIDDEN_ARGS $PRIOR_ARGS --seed ${SEED}"
    TRAINING_ARGS='--val_batch_size 1 --batch_size 4 --accumulate_steps 2 --lr 5e-4 --use_adam --num_epochs 600 --lr_decay_factor 0.5 --lr_decay_steps 300 --normalize_kl --normalize_nll --tune_on_nll --val_teacher_forcing --teacher_forcing_steps -1'
    mkdir -p $WORKING_DIR
    CUDA_VISIBLE_DEVICES=$GPU python -u locs/experiments/motion_experiment.py \
      --gpu --mode train --data_path $DATA_PATH --working_dir $WORKING_DIR \
      $MODEL_ARGS $TRAINING_ARGS |& tee "${WORKING_DIR}results.txt"
    CUDA_VISIBLE_DEVICES=$GPU python -u locs/experiments/motion_experiment.py \
      --gpu --report_error_norm --mode eval --load_best_model \
      --data_path $DATA_PATH --working_dir $WORKING_DIR $MODEL_ARGS \
      $TRAINING_ARGS |& tee "${WORKING_DIR}eval_results.txt"
done
