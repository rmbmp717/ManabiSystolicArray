#
# NISHIHARU
#
import numpy as np

class PE:
    """
    Processing Element (PE) class.
    Holds the value of B (b_val) and processes elements of A.
    """
    def __init__(self, row, col, b_val=0):
        self.row = row  # PE row index
        self.col = col  # PE column index
        self.b_val = b_val  # Value from matrix B
        self.a_reg = 0  # Value from matrix A
        self.partial_sum = 0  # Partial sum for accumulation

        # Reference to the top cell (linked PE)
        self.top = None
        self.left = None

    def calc_step(self):
        """
        Calculation step:
        Multiply a_reg by b_val and store the result in partial_sum.
        """
        self.partial_sum = self.a_reg * self.b_val

    def shift_right(self):
        """
        Shift step:
        Accumulate the partial_sum from the top cell.
        """
        if self.left:
            self.a_reg = self.left.a_reg

    def shift_step(self):
        """
        Shift step:
        Accumulate the partial_sum from the top cell.
        """
        if self.top:
            self.partial_sum += self.top.partial_sum

    def reset(self):
        """
        Reset partial_sum and a_reg.
        """
        self.partial_sum = 0

    def flush_out(self):
        """
        Return the partial_sum of the bottom-most row in the systolic array as an array.
        """
        output = []  # List to store partial_sum of the bottom-most row
        for c in range(self.cols):
            output.append(self.pes[self.rows - 1][c].partial_sum)  # Collect partial_sum from each PE in the bottom-most row
        return np.array(output)  # Return as a NumPy array

class SystolicArray:

    def __init__(self, B):
        """
        Initialize the PE array with matrix B.
        """
        B = np.array(B)  # Convert B to a NumPy array

        # Get the size of the array
        self.rows = B.shape[0]  # Number of rows
        self.cols = B.shape[1]  # Number of columns

        # Construct the PE array
        self.pes = []
        for r in range(self.rows):
            row_pes = []
            for c in range(self.cols):
                pe = PE(r, c, b_val=B[r, c])
                row_pes.append(pe)
            self.pes.append(row_pes)

        # Set links to the top PEs
        self._link_pes()

    def _link_pes(self):
        """
        Link PEs vertically (top-to-bottom).
        """
        for r in range(self.rows):
            for c in range(self.cols):
                if r > 0:
                    self.pes[r][c].top = self.pes[r - 1][c]
                if c > 0:
                    self.pes[r][c].left = self.pes[r][c - 1]

    def execute_calc_step(self):
        """
        Execute the calc_step method for all PEs in the systolic array.
        """
        for r in range(self.rows):
            for c in range(self.cols):
                self.pes[r][c].calc_step()

    def flush_out(self):
        """
        Return the partial_sum of the bottom-most row in the systolic array as an array.
        """
        output = []  # List to store partial_sum of the bottom-most row
        for c in range(self.cols):
            output.append(self.pes[self.rows - 1][c].partial_sum)  # Collect partial_sum from each PE in the bottom-most row
        return np.array(output)  # Return as a NumPy array

    def reset(self):
        """
        Reset all PEs in the array.
        """
        for r in range(self.rows):
            for c in range(self.cols):
                self.pes[r][c].reset()

    def right_shift(self):
        # Perform shift_right for all PEs
        for r in range(self.rows):
            for c in range(self.cols - 1, 0, -1):
                self.pes[r][c].shift_right()

    def shift_step(self):
        # Perform shift_step for all PEs
        for r in range(self.rows):
            for c in range(self.cols):
                self.pes[r][c].shift_step()

    def _trace(self, step, A, B):
        """
        Debug the state of the PE array at each step.
        """
        print(f"\nStep={step}")
        print("Contents of A:")
        print(np.array(A))
        print("\nContents of B:")
        print(np.array(B))

        # Display the state of b_val
        B_val_mat = [[self.pes[r][c].b_val for c in range(self.cols)] for r in range(self.rows)]
        print("\nB_val (Values of B stored in the PEs):")
        print(np.array(B_val_mat))

        # Display the state of partial_sum
        PS_mat = [[self.pes[r][c].partial_sum for c in range(self.cols)] for r in range(self.rows)]
        print("\npartial_sum (Intermediate partial sums):")
        print(np.array(PS_mat))

        # Display the state of a_reg
        A_reg_mat = [[self.pes[r][c].a_reg for c in range(self.cols)] for r in range(self.rows)]
        print("\na_reg (Values of A stored in the PEs):")
        print(np.array(A_reg_mat))

    def multiply(self, A, B):

        A = np.array(A)  # Convert A to a NumPy array
        B = np.array(B)  # Convert B to a NumPy array

        # Initialize the result matrix
        out = np.zeros((A.shape[0], B.shape[1]), dtype=int)

        # Process each row of A
        for a_row_i in range(A.shape[0] + (A.shape[0]-1)):

            # Reset all PEs
            self.reset()

            # **Right shift**
            self.right_shift()

            # Assign the next row of A to the leftmost PEs
            if a_row_i < A.shape[0]:
                a_row = A[a_row_i]
            for r in range(self.rows):
                if a_row_i < A.shape[0]:
                    self.pes[r][0].a_reg = a_row[r]

            # Perform calc_step for all PEs
            self.execute_calc_step()

            # Perform shift_step for all PEs
            self.shift_step()

            # **Collect results**
            flush_out = self.flush_out()
            for col in range(self.cols):
                row_index = a_row_i - col
                if 0 <= row_index < out.shape[0]:  # Only store values within the array bounds
                    out[row_index, col] = flush_out[col]

        return out


def main():
    M = 3
    N = 9
    P = 3
    A_new = np.random.randint(0, 100, (M, N))  # Generate random integers between 0 and 99
    B_new = np.random.randint(0, 100, (N, P))  # Generate random integers between 0 and 99
    A = A_new
    B = B_new
    
    # Expected result (calculated with NumPy)
    A_np = np.array(A)
    B_np = np.array(B)
    expected = A_np.dot(B_np)

    # Create a systolic array and calculate
    sa = SystolicArray(B)
    result = sa.multiply(A, B)

    # Display results
    print(A_np)
    print(B_np)

    print("\n=== Matrix multiplication using NumPy ===")
    print(expected)

    print("\n=== Matrix multiplication using Systolic Array ===")
    print(result)

    # Verify the results
    assert np.allclose(result, expected), f"Mismatch: {result} != {expected}"
    print("\n=== Verification successful ===")


if __name__ == "__main__":
    main()
