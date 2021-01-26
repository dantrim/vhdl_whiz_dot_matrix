package sim_fifo is
    -- protected ~ class
    type sim_fifo is protected

        -- add a new element to the list
        procedure push(constant data : in integer);

        -- return the oldest element from the list without removing it
        impure function peek return integer;

        -- remove and return the oldest element from the list
        -- impure = has side effects
        impure function pop return integer;

        -- return true if there are 0 elements in the list, otherwise false
        -- empty
        impure function empty return boolean;

    end protected;
end package;

-- implementation
package body sim_fifo is

    type sim_fifo is protected body

        -- declare incomplete type (e.g. forward declare) so that you can create
        -- the access type to the record type
        type item;
        -- "is access" is how you declare a pointer type, here ptr is a pointer to type of "item"
        type ptr is access item;

        -- record is ~ C struct
        type item is record
            data : integer;
            next_item : ptr;
        end record;

        -- root of the linked list
        variable root : ptr;

        -----------------------------------------------------------
        -- push
        -----------------------------------------------------------
        procedure push(constant data : in integer) is
            variable new_item : ptr;
            variable node : ptr;
        begin
            -- "new" is VHDL keyword, create a new item in dynamic memory
            -- "new" is used only in testbenches, it is not synthesizable
            new_item := new item;
            new_item.data := data;

            if root = null then
                root := new_item;
            else
                node := root;
                while node.next_item /= null loop
                    node := node.next_item;
                end loop;
                node.next_item := new_item;
            end if;
        end procedure;

        -----------------------------------------------------------
        -- pop
        -----------------------------------------------------------
        impure function pop return integer is
            variable node : ptr;
            variable ret_val : integer;
        begin
            node := root;
            root := root.next_item;
            ret_val := node.data;
            deallocate(node);
            return ret_val;
        end function;

        -----------------------------------------------------------
        -- peek
        -----------------------------------------------------------
        impure function peek return integer is
        begin
            return root.data;
        end function;

        -----------------------------------------------------------
        -- empty
        -----------------------------------------------------------
        impure function empty return boolean is
        begin
            return root = null;
        end function;

    end protected body;

end package body;