#include <stdio.h>
#include <stdlib.h>
#include <alloca.h>

#define BLOCKS_COUNT 1024 //* 1024 
#define BLOCK_SIZE  8192

void *my_malloc( size_t size ) {
    return malloc ( size );
    //return realloc( NULL, size );
    //return calloc( 1, size );
    //return alloca(size);
}

void my_free( void *ptr ) {
    free( ptr );
}

int main( int argc, char **argv ) {
    int clean = 0;
    size_t *block_ptr_list = NULL;
    size_t block_index = BLOCKS_COUNT;

    block_ptr_list = my_malloc( BLOCKS_COUNT * sizeof( size_t ) );
    if ( block_ptr_list == NULL ) {
        printf("Memory allocation error in __FILE__(__LINE__)\n");
        return 1;
    }

    while( block_index != 0 ) {
        int *temp_buffer = my_malloc( BLOCK_SIZE * sizeof( int ) );
        if ( temp_buffer == NULL ) {
            printf("Memory allocation error in __FILE__(__LINE__)\n");
            break;
        }

        *(block_ptr_list + ( BLOCKS_COUNT - block_index-- )) = (size_t)temp_buffer;
        
        int i;
        for (i = 0; i < BLOCK_SIZE; i++ ) {
            if ( *(temp_buffer+i) != 0 )
                clean += 1;
        }
    }

    // clean
    while ( block_index < BLOCKS_COUNT )
        my_free((void *)*(block_ptr_list + block_index++));

    my_free( block_ptr_list );

    if ( clean > 0 )
        printf("Memory is not clean (%d).\n", clean);
    else
        printf("Memory is clean.\n");
    return 0;
}
