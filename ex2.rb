$label_counter = 1
def translate_file(vm_path)
  if !File.file?(vm_path)
    return 'VM File does not exists!'
  end
  lines = IO.readlines(vm_path)
  output = ''
  file_name = vm_path.split('\\').last[0..-3]
  for line in lines
    line = line.split
    case line[0]
      when 'add'
        output << add
      when 'sub'
        output << sub
      when 'neg'
        output << neg
      when 'eq'
        output << eq
      when 'gt'
        output << gt
      when 'lt'
        output << lt
      when 'and'
        output << f_and
      when 'or'
        output << f_or
      when 'not'
        output << f_not
      when 'push'
        output << push(line[1], line[2], file_name)
      when 'pop'
        output << pop(line[1], line[2], file_name)
      when 'label'
        output << label(line[1], file_name)
      when 'goto'
        output << goto(line[1], file_name)
      when 'if-goto'
        output << if_goto(line[1], file_name)
      when 'function'
        output << f_function(line[1], line[2])
      when 'call'
        output << f_call(line[1], line[2])
      when 'return'
        output << f_return
    end
  end
  return output
end

def pop_to_D
  output = "@SP\n" #get SP into A
  output << "M=M-1\n" #decrease SP by 1
  output << "A=M\n" #point to the new SP
  output << "D=M\n" #pop the previous variable to D register
  output << "A=A-1\n" #decrease SP by 1
end

def pre_unary
  output = "@SP\n" #get SP into A
  output << "A=M-1\n"
end

def add
  output = "\n//add\n"
  output << pop_to_D
  output << "M=M+D\n" #insert into stack top D + current stack top
end

def sub
  output = "\n//sub\n"
  output << pop_to_D
  output << "M=M-D\n" #insert into stack top D - current stack top
end

def neg
  output = "\n//neg\n"
  output << pre_unary
  output << "M=-M\n" #update stack top to it's negative
end

def eq
  output = "\n//eq\n"
  output << pop_to_D
  output << "A=M\n" #in D there is the first arg, in A the second
  output << "D=A-D\n" #if D and A are equal = D is 0.
  output << '@IF_TRUE' << $label_counter.to_s << "\n"
  output << "D;JEQ\n"
  output << "@SP\n"
  output << "A=M-1\n"
  output << "M=0\n"
  output << '@END' << $label_counter.to_s << "\n"
  output << "0;JEQ\n"
  output << '(IF_TRUE' << $label_counter.to_s << ")\n"
  output << "@SP\n"
  output << "A=M-1\n"
  output << "M=-1\n"
  output << '(END' << $label_counter.to_s << ")\n"
  $label_counter = $label_counter + 1
  output
end

def gt
  output = "\n//gt\n"
  output << pop_to_D
  output << "A=M\n" #in D there is the first arg, in A the second
  output << "D=A-D\n" #if D and A are equal = D is 0.
  output << '@IF_TRUE' << $label_counter.to_s << "\n"
  output << "D;JGT\n"
  output << "@SP\n"
  output << "A=M-1\n"
  output << "M=0\n"
  output << '@END' << $label_counter.to_s << "\n"
  output << "0;JEQ\n"
  output << '(IF_TRUE' << $label_counter.to_s << ")\n"
  output << "@SP\n"
  output << "A=M-1\n"
  output << "M=-1\n"
  output << '(END' << $label_counter.to_s << ")\n"
  $label_counter = $label_counter + 1
  output
end

def lt
  output = "\n//lt\n"
  output << pop_to_D
  output << "A=M\n" #in D there is the first arg, in A the second
  output << "D=A-D\n" #if D and A are equal = D is 0.
  output << '@IF_TRUE' << $label_counter.to_s << "\n"
  output << "D;JLT\n"
  output << "@SP\n"
  output << "A=M-1\n"
  output << "M=0\n"
  output << '@END' << $label_counter.to_s << "\n"
  output << "0;JEQ\n"
  output << '(IF_TRUE' << $label_counter.to_s << ")\n"
  output << "@SP\n"
  output << "A=M-1\n"
  output << "M=-1\n"
  output << '(END' << $label_counter.to_s << ")\n"
  $label_counter = $label_counter + 1
  output
end

def f_and
  output = "\n//f_and\n"
  output << pop_to_D
  output << "M=M&D\n"
end

def f_or
  output = "\n//f_or\n"
  output << pop_to_D
  output << "M=M|D\n"
end

def f_not
  output = "\n//f_not\n"
  output << pre_unary
  output << "M=!M\n"
end

def push(segment, index, path)
  output = "\n//push"
  output << ' segment: ' << segment
  output << ' index: ' << index << "\n"
  case segment
    when 'constant'
      output << push_constant(index)
    when 'local'
      output << push_local(index)
    when 'argument'
      output << push_argument(index)
    when 'this'
      output << push_this(index)
    when 'that'
      output << push_that(index)
    when 'temp'
      output << push_temp(index)
    when 'static'
      output << push_static(index, path)
    when 'pointer'
      output << push_pointer(index)
  end
end

def pop(segment, index, path)
  output = "\n//pop"
  output << ' segment: ' << segment
  output << ' index: ' << index
  output << "\n"
  case segment
    when 'local'
      output << pop_local(index)
    when 'argument'
      output << pop_argument(index)
    when 'this'
      output << pop_this(index)
    when 'that'
      output << pop_that(index)
    when 'temp'
      output << pop_temp(index)
    when 'static'
      output << pop_static(index, path)
    when 'pointer'
      output << pop_pointer(index)
  end
end

def push_constant(index)
  output = '@' << index << "\n"
  output << "D=A\n"
  output << push_from_D
end

def push_local(index)
  output = "@LCL\n"
  output << "D=M\n" #D = RAM[1]
  output << '@' << index << "\n" #A = index
  output << "A=D+A\n" #A = RAM[1] + index
  output << "D=M\n" #D = RAM[RAM[1] + index]
  output << push_from_D
end

def pop_local(index)
  output = "@LCL\n"
  output << "D=M\n" #D = RAM[1]
  output << '@' << index << "\n" #A = index
  output << "D=D+A\n" #D = RAM[1] + index
  output << "@R13\n" #temp register
  output << "M=D\n" #reg13 = RAM[1] + index
  output << pop_to_D #D = top of stack
  output << "@R13\n"
  output << "A=M\n" #A = RAM[1] + index
  output << "M=D\n" #RAM[RAM[1] + index] = top of stack
end

def push_argument(index)
  output = "@ARG\n"
  output << "D=M\n" #D = RAM[2]
  output << '@' << index << "\n" #A = index
  output << "A=D+A\n" #A = RAM[2] + index
  output << "D=M\n" #D = RAM[RAM[2] + index]
  output << push_from_D
end

def pop_argument(index)
  output = "@ARG\n"
  output << "D=M\n" #D = RAM[2]
  output << '@' << index << "\n" #A = index
  output << "D=D+A\n" #D = RAM[2] + index
  output << "@R13\n" #temp register
  output << "M=D\n" #reg13 = RAM[2] + index
  output << pop_to_D #D = top of stack
  output << "@R13\n"
  output << "A=M\n" #A = RAM[2] + index
  output << "M=D\n" #RAM[RAM[2] + index] = top of stack
end

def push_this(index)
  output = "@THIS\n"
  output << "D=M\n" #D = RAM[3]
  output << '@' << index << "\n" #A = index
  output << "A=D+A\n" #A = RAM[3] + index
  output << "D=M\n" #D = RAM[RAM[3] + index]
  output << push_from_D
end

def pop_this(index)
  output = "@THIS\n"
  output << "D=M\n" #D = RAM[3]
  output << '@' << index << "\n" #A = index
  output << "D=D+A\n" #D = RAM[3] + index
  output << "@R13\n" #temp register
  output << "M=D\n" #reg13 = RAM[3] + index
  output << pop_to_D #D = top of stack
  output << "@R13\n"
  output << "A=M\n" #A = RAM[3] + index
  output << "M=D\n" #RAM[RAM[3] + index] = top of stack
end

def push_that(index)
  output = "@THAT\n"
  output << "D=M\n" #D = RAM[4]
  output << '@' << index << "\n" #A = index
  output << "A=D+A\n" #A = RAM[4] + index
  output << "D=M\n" #D = RAM[RAM[4] + index]
  output << push_from_D
end

def pop_that(index)
  output = "@THAT\n"
  output << "D=M\n" #D = RAM[4]
  output << '@' << index << "\n" #A = index
  output << "D=D+A\n" #D = RAM[4] + index
  output << "@R13\n" #temp register
  output << "M=D\n" #reg13 = RAM[4] + index
  output << pop_to_D #D = top of stack
  output << "@R13\n"
  output << "A=M\n" #A = RAM[4] + index
  output << "M=D\n" #RAM[RAM[4] + index] = top of stack
end

def push_temp(index)
  output = "@5\n" #const for temp
  output << "D=A\n" #D = 5
  output << '@' << index << "\n" #A = index
  output << "A=A+D\n" #A = index + 5
  output << "D=M\n" #D = RAM[index + 5]
  output << push_from_D
end

def pop_temp(index)
  output = "@5\n" #const for temp
  output << "D=A\n" #D = 5
  output << '@' << index << "\n" #A = index
  output << "D=A+D\n" #D = index + 5
  output << "@R13\n"
  output << "M=D\n" #reg13 = index + 5
  output << pop_to_D #D = top of stack
  output << "@R13\n"
  output << "A=M\n" #A = index + 5
  output << "M=D\n" #RAM[index + 5] = top of stack
end

def push_pointer(index)
  output = ''
  case index
    when '0'
      output << "@THIS\n"
    when '1'
      output << "@THAT\n"
  end
  output << "D=M\n" #D = RAM[THIS/THAT]
  output << push_from_D
end

def pop_pointer(index)
  output = pop_to_D #D = top of stack
  case index
    when '0'
      output << "@THIS\n"
    when '1'
      output << "@THAT\n"
  end
  output << "M=D\n" #RAM[THIS/THAT] = top of stack
end

def push_static(index, file_name)
  output = '@' << file_name << index << "\n"
  output << "D=M\n"
  output << push_from_D
end

def pop_static(index, file_name)
  output = pop_to_D
  output << '@' << file_name << index << "\n"
  output << "M=D\n"
end

def push_from_D
  output = "@SP\n"
  output << "A=M\n"
  output << "M=D\n"
  output << "D=A+1\n"
  output << "@SP\n"
  output << "M=D\n"
end

def translate_folder(folder_path)
  output = init
  all_files = Dir.entries(folder_path)
  for file in all_files
    if file.end_with? '.vm'
      output << translate_file(folder_path + '\\' + file)
    end
  end
  dir_name = folder_path.split('\\').last
  out_file = folder_path + '\\' + dir_name + '.asm'
  File.open(out_file, 'w') do |f|
    f.puts(output)
  end
end



#-------------------------------------------------------

# Start of level #2
# There is a minor change in level #1, basically Ruby syntax

def init
  output = "// Initialize the SP to 256\n"
  output << "@256\n"
  output << "D=A\n"
  output << "@SP\n"
  output << "M=D\n"
  output << f_call('Sys.init', 0)
end

def label(func_name, file_name)
  output = '(' << file_name << func_name << ")\n"
end

def goto(func_name, file_name)
  output = '@' << file_name << func_name << "\n"
  output << "0;JEQ\n"
end

def if_goto(func_name, file_name)
  output = pop_to_D
  output << '@' << file_name << func_name << "\n"
  output << "D;JNE\n"
end

def f_call(func_name, n_args)
  output = "//function call\n"
  label = func_name + '_return_address' + $label_counter.to_s
  $label_counter = $label_counter + 1
  output << '@' + label +  "\n"
  output << "D=A\n"
  output << push_from_D # push return address
  output << "@LCL\n"
  output << "D=M\n"
  output << push_from_D # push LCL
  output << "@ARG\n"
  output << "D=M\n"
  output << push_from_D # push ARG
  output << "@THIS\n"
  output << "D=M\n"
  output << push_from_D # push THIS
  output << "@THAT\n"
  output << "D=M\n"
  output << push_from_D # push THAT
  output << '@' + n_args.to_s + "\n"
  output << "D=A\n" # D = n-args
  output << "@SP\n"
  output << "D=M-D\n" # D = SP - N
  output << "@5\n"
  output << "D=D-A\n" # D = SP - N - 5
  output << "@ARG\n"
  output << "M=D\n" # ARG = SP - N - 5
  output << "@SP\n"
  output << "D=M\n"
  output << "@LCL\n"
  output << "M=D\n" # LCL = SP
  output << '@' + func_name + "\n"
  output << "0;JEQ\n" # goto f
  output << '(' + label + ")\n"
end

def f_return
  output = "//return\n"
  output << "@LCL\n"
  output << "D=M\n"
  output << "@R14\n"
  output << "M=D\n" # R14(frame) = LCL
  output << "@5\n"
  output << "A=D-A\n" # A = frame - 5
  output << "D=M\n" # D = *(frame - 5)
  output << "@R15\n"
  output << "M=D\n" # R15(RET) = *(frame - 5)
  output << pop_to_D
  output << "@ARG\n"
  output << "A=M\n" # A = *ARG
  output << "M=D\n" # *ARG = pop()
  output << "@ARG\n"
  output << "D=M\n"
  output << "@SP\n"
  output << "M=D+1\n" # SP = ARG + 1
  output << "@R14\n"
  output << "A=M-1\n"
  output << "D=M\n" # D = *(frame - 1)
  output << "@THAT\n"
  output << "M=D\n" # THAT = *(frame - 1)
  output << "@R14\n"
  output << "D=M\n" # D = frame
  output << "@2\n"
  output << "A=D-A\n" # A = frame - 2
  output << "D=M\n" # D = *(frame - 2)
  output << "@THIS\n"
  output << "M=D\n" # THIS = *(frame - 2)
  output << "@R14\n"
  output << "D=M\n" # D = frame
  output << "@3\n"
  output << "A=D-A\n" # A = frame - 3
  output << "D=M\n" # D = *(frame - 3)
  output << "@ARG\n"
  output << "M=D\n" # ARG = *(frame - 3)
  output << "@R14\n"
  output << "D=M\n" # D = frame
  output << "@4\n"
  output << "A=D-A\n" # A = frame - 4
  output << "D=M\n" # D = *(frame - 4)
  output << "@LCL\n"
  output << "M=D\n" # LCL = *(frame - 4)
  output << "@R15\n" # RET
  output << "A=M\n"
  output << "0;JEQ\n" # goto RET
end

def f_function(func_name, n_local_vars)
  output = "//function declaration\n"
  output << '(' << func_name << ")\n" # label for start function init
  output << '@' + n_local_vars.to_s + "\n"
  output << "D=A\n" # now D holds num of locals
  output << '(' + func_name + "_init)\n" # label for start init
  output << '@' + func_name + "_body\n"
  output << "D;JEQ\n" # if counter = 0 - go to function body
  output << "@SP\n"
  output << "A=M\n"
  output << "M=0\n"
  output << "@SP\n"
  output << "M=M+1\n"
  output << "D=D-1\n" # decrease counter by 1
  output << '@' + func_name + "_init\n"
  output << "0;JEQ\n"
  output << '(' + func_name + "_body)\n"
end

translate_folder(ARGV[0])
