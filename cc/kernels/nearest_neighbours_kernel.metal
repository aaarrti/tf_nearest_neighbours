#include <metal_stdlib>thread int32_t index_2d_flat(const thread int32_t& index_0, const thread int32_t& index_1, constant int32_t& shape_1) {  return index_1 + index_0 * shape_1;}thread int32_t index_3d_flat(const thread int32_t& index_0, const thread int32_t& index_1,                             thread int32_t& index_2, constant int32_t& shape_1, constant int32_t& shape_2) {  return index_2 + index_1 * shape_2 + index_0 * shape_2 * shape_1;}kernel void nearest_neighbours(    // inputs    constant float* token_embeddings,    constant float* embedding_matrix,    // output    device float* outputs,    // attributes    constant int32_t& sequence_length,    constant int32_t& vocab_size,    constant int32_t& embed_dim,    // thread id    uint2 tid [[thread_position_in_grid]]) {  const thread int32_t index_in_batch = tid[0];  const thread int32_t index_in_sequence = tid[1];  thread float min_dist = 100;  thread int32_t argmin = 100;  for (thread int32_t word_index = 0; word_index != vocab_size; word_index++) {    thread float dist = 0;    for (thread int32_t i = 0; i != embed_dim; i++) {      const thread int32_t index_in_embedding_matrix = index_2d_flat(word_index, i, embed_dim);      const thread  int32_t index_in_token_embeddings = index_3d_flat(index_in_batch, index_in_sequence, i, sequence_length, embed_dim);      const thread float val1 = embedding_matrix[index_in_embedding_matrix];      const thread float val2 = token_embeddings[index_in_token_embeddings];      dist += metal::exp2(val1 - val2);    }    dist = metal::sqrt(dist);    if (dist < min_dist) {      min_dist = dist;      argmin = word_index;    }  }  for (thread  int32_t i = 0; i != embed_dim; i++) {    const thread  int32_t index_in_output = index_3d_flat(index_in_batch, index_in_sequence, i, sequence_length, embed_dim);    const thread  int32_t index_in_embedding_matrix = index_2d_flat(argmin, i, embed_dim);    outputs[index_in_output] = embedding_matrix[index_in_embedding_matrix];  }}