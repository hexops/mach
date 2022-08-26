// TODO: implement custom allocator support

// /*! @brief
//  *
//  *  @sa @ref init_allocator
//  *  @sa @ref glfwInitAllocator
//  *
//  *  @since Added in version 3.4.
//  *
//  *  @ingroup init
//  */
// typedef struct GLFWallocator
// {
//     GLFWallocatefun allocate;
//     GLFWreallocatefun reallocate;
//     GLFWdeallocatefun deallocate;
//     void* user;
// } GLFWallocator;

// /*! @brief The function pointer type for memory allocation callbacks.
//  *
//  *  This is the function pointer type for memory allocation callbacks.  A memory
//  *  allocation callback function has the following signature:
//  *  @code
//  *  void* function_name(size_t size, void* user)
//  *  @endcode
//  *
//  *  This function must return either a memory block at least `size` bytes long,
//  *  or `NULL` if allocation failed.  Note that not all parts of GLFW handle allocation
//  *  failures gracefully yet.
//  *
//  *  This function may be called during @ref glfwInit but before the library is
//  *  flagged as initialized, as well as during @ref glfwTerminate after the
//  *  library is no longer flagged as initialized.
//  *
//  *  Any memory allocated by this function will be deallocated during library
//  *  termination or earlier.
//  *
//  *  The size will always be greater than zero.  Allocations of size zero are filtered out
//  *  before reaching the custom allocator.
//  *
//  *  @param[in] size The minimum size, in bytes, of the memory block.
//  *  @param[in] user The user-defined pointer from the allocator.
//  *  @return The address of the newly allocated memory block, or `NULL` if an
//  *  error occurred.
//  *
//  *  @pointer_lifetime The returned memory block must be valid at least until it
//  *  is deallocated.
//  *
//  *  @reentrancy This function should not call any GLFW function.
//  *
//  *  @thread_safety This function may be called from any thread that calls GLFW functions.
//  *
//  *  @sa @ref init_allocator
//  *  @sa @ref GLFWallocator
//  *
//  *  @since Added in version 3.4.
//  *
//  *  @ingroup init
//  */
// typedef void* (* GLFWallocatefun)(size_t size, void* user);

// /*! @brief The function pointer type for memory reallocation callbacks.
//  *
//  *  This is the function pointer type for memory reallocation callbacks.
//  *  A memory reallocation callback function has the following signature:
//  *  @code
//  *  void* function_name(void* block, size_t size, void* user)
//  *  @endcode
//  *
//  *  This function must return a memory block at least `size` bytes long, or
//  *  `NULL` if allocation failed.  Note that not all parts of GLFW handle allocation
//  *  failures gracefully yet.
//  *
//  *  This function may be called during @ref glfwInit but before the library is
//  *  flagged as initialized, as well as during @ref glfwTerminate after the
//  *  library is no longer flagged as initialized.
//  *
//  *  Any memory allocated by this function will be deallocated during library
//  *  termination or earlier.
//  *
//  *  The block address will never be `NULL` and the size will always be greater than zero.
//  *  Reallocations of a block to size zero are converted into deallocations.  Reallocations
//  *  of `NULL` to a non-zero size are converted into regular allocations.
//  *
//  *  @param[in] block The address of the memory block to reallocate.
//  *  @param[in] size The new minimum size, in bytes, of the memory block.
//  *  @param[in] user The user-defined pointer from the allocator.
//  *  @return The address of the newly allocated or resized memory block, or
//  *  `NULL` if an error occurred.
//  *
//  *  @pointer_lifetime The returned memory block must be valid at least until it
//  *  is deallocated.
//  *
//  *  @reentrancy This function should not call any GLFW function.
//  *
//  *  @thread_safety This function may be called from any thread that calls GLFW functions.
//  *
//  *  @sa @ref init_allocator
//  *  @sa @ref GLFWallocator
//  *
//  *  @since Added in version 3.4.
//  *
//  *  @ingroup init
//  */
// typedef void* (* GLFWreallocatefun)(void* block, size_t size, void* user);

// /*! @brief The function pointer type for memory deallocation callbacks.
//  *
//  *  This is the function pointer type for memory deallocation callbacks.
//  *  A memory deallocation callback function has the following signature:
//  *  @code
//  *  void function_name(void* block, void* user)
//  *  @endcode
//  *
//  *  This function may deallocate the specified memory block.  This memory block
//  *  will have been allocated with the same allocator.
//  *
//  *  This function may be called during @ref glfwInit but before the library is
//  *  flagged as initialized, as well as during @ref glfwTerminate after the
//  *  library is no longer flagged as initialized.
//  *
//  *  The block address will never be `NULL`.  Deallocations of `NULL` are filtered out
//  *  before reaching the custom allocator.
//  *
//  *  @param[in] block The address of the memory block to deallocate.
//  *  @param[in] user The user-defined pointer from the allocator.
//  *
//  *  @pointer_lifetime The specified memory block will not be accessed by GLFW
//  *  after this function is called.
//  *
//  *  @reentrancy This function should not call any GLFW function.
//  *
//  *  @thread_safety This function may be called from any thread that calls GLFW functions.
//  *
//  *  @sa @ref init_allocator
//  *  @sa @ref GLFWallocator
//  *
//  *  @since Added in version 3.4.
//  *
//  *  @ingroup init
//  */
// typedef void (* GLFWdeallocatefun)(void* block, void* user);
