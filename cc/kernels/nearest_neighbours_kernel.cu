#include "tensorflow/core/framework/op_kernel.h"
#include "nearest_neighbours.h"


namespace tensorflow {
  namespace functor {

    __device__ int index_2d_flat(int index_0, int index_1, int shape_1) {
      return index_1 + index_0 * shape_1;
    }

    __device__ int index_3d_flat(int index_0, int index_1, int index_2, int shape_1, int shape_2) {
      return index_2 + index_1 * shape_2 + index_0 * shape_2 * shape_1;
    }


    // Define the CUDA kernel.
    template<typename T>
    __global__ void NearestNeighboursCudaKernel(const T *token_embeddings, const T *embedding_matrix, T *output,
                                                const int num_tokens, const int vocab_size, const int embedding_dim) {

      const int index_in_batch = threadIdx.x;
      const int index_in_sequence = threadIdx.y;

      T min_dist = 100;
      int argmin = 100;


      for (int word_index = 0; word_index != vocab_size; word_index++) {

        T dist = 0;

        for (int i = 0; i != embedding_dim; i++) {
          const int index_in_embedding_matrix = index_2d_flat(word_index, i, embedding_dim);
          const int index_in_token_embeddings = index_3d_flat(index_in_batch, index_in_sequence, i, num_tokens,
                                                              embedding_dim);
          const T val1 = embedding_matrix[index_in_embedding_matrix];
          const T val2 = token_embeddings[index_in_token_embeddings];
          dist += (T) pow(val1 - val2, 2);
        }

        dist = (T) sqrt(dist);
        if (dist < min_dist) {
          min_dist = dist;
          argmin = word_index;
        }
      }

      for (int i = 0; i != embedding_dim; i++) {
        const int index_in_output = index_3d_flat(index_in_batch, index_in_sequence, i, num_tokens, embedding_dim);
        const int index_in_embedding_matrix = index_2d_flat(argmin, i, embedding_dim);
        output[index_in_output] = embedding_matrix[index_in_embedding_matrix];
      }

    }


    template<typename T>
    struct NearestNeighboursFunctor<GPUDevice, T> {

      void operator()(const GPUDevice &device, const Tensor *token_embeddings, const Tensor *embedding_matrix,
                      Tensor *output_tensor) {

        const int batch_size = static_cast<int>(token_embeddings->dim_size(0));
        const int vocab_size = static_cast<int>(embedding_matrix->dim_size(0));
        const int num_tokens = static_cast<int>(token_embeddings->dim_size(1));
        const int embedding_dim = static_cast<int>(token_embeddings->dim_size(2));

        const T *token_embeddings_flat = token_embeddings->flat<T>().data();
        const T *embedding_matrix_flat = embedding_matrix->flat<T>().data();
        T *output_flat = output_tensor->flat<T>().data();

        NearestNeighboursCudaKernel<T><<<batch_size, num_tokens>>>(token_embeddings_flat, embedding_matrix_flat,
                                                                   output_flat, num_tokens, vocab_size, embedding_dim);
      }
    };

    // Explicitly instantiate functors for the types of OpKernels registered.
    template
    struct NearestNeighboursFunctor<GPUDevice, float>;
  }
}