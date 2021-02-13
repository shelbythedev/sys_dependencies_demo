def run_app
    # commands (make any updates to script values here)
    depend = "DEPEND"
    install = "INSTALL"
    remove = "REMOVE"
    list = "LIST"
    end_command = "END"

    @depends_on = []
    @needed_by = []
    @installed = []

    # load file and parse each line
    load_file.each do |line|
        # split the line and fetch the command and all arguments
        parsed_line = line.chomp!.partition(" ")
        command = parsed_line.first
        args = parsed_line.last

        # echo the command currently executing
        puts "#{command} #{args}"
        
        case command
        when depend
            set_dependencies(args)

        when install
            install_component(args, nil)

        when remove
            remove_component(args, nil)

        when list
            list_components()

        when end_command
            return

        else
            puts "  ERROR: Unknown command '#{command}'"
        end
    end
end

private

def load_file
    # use first cli arg as path, discard all other inputs
    file_path, *misc = ARGV

    # for our purposes, and for testing, 
    # we'll load the sample file if arg is excluded
    file_path ||= "./sample_input.txt"

    File.open(file_path)    
end

# compile dependencies for each component
def set_dependencies components
    parsed = components.split(" ")
    component = parsed.first
    dependencies = parsed.drop(1)

    # get the component, and add the dependencies in the @depends_on array
    # if not in list, add.
    depends_on_results = @depends_on.detect {|comp| comp[:name] == component}

    if !depends_on_results
        @depends_on << {
            name: component,
            dependencies: dependencies
        }
    else
        depends_on_results[:dependencies] << dependencies
    end

    # do the same for each dependency, and add to the @needed_by array for reverse functionality
    dependencies.each do |dependency|
        needed_by_results = @needed_by.detect {|dep| dep[:name] == dependency}

        if !needed_by_results
            @needed_by << {
                name: dependency,
                needed_by: [component]
            }
        else
            needed_by_results[:needed_by] << component
        end
    end
end

# install a component and it's dependencies
def install_component (component, is_recursive)
    # fetch component's dependencies
    has_dependencies = @depends_on.detect {|comp| comp[:name] == component}

    # iterate through dependencies and run this command for each, first
    if has_dependencies
        has_dependencies[:dependencies].each do |dependency|
            install_component(dependency, true)
        end
    end

    # check to see if already installed, and install if not
    if !@installed.include? component
        puts "  Installing #{component}"
        @installed << component
    else
        puts "  #{component} is already installed." unless is_recursive
    end
end

# remove a component and any no-longer-needed dependencies
def remove_component (component, is_recursive)
    if @installed.include? component
        # fetch any components that may still need this as a dependency
        is_needed_by = @needed_by.detect{|comp| comp[:name] == component}

        # iterate through list of required installs, and see if they are still on system
        if is_needed_by
            is_needed_by[:needed_by].each do |needed_by|
                if @installed.include? needed_by
                    # if component is still needed by an installed component, fail removal
                    puts "  #{component} is still needed." unless is_recursive
                    return
                end
            end
        end

        # remove component from installed list
        puts "  Removing #{component}"
        @installed.delete(component)

        if !is_recursive
            # see if any dependencies can now be removed
            has_dependencies = @depends_on.detect {|comp| comp[:name] == component}

            if has_dependencies
                has_dependencies[:dependencies].each do |dependency|
                    remove_component(dependency, true)
                end
            end
        end
    else
        puts "  #{component} is not installed."
    end
end

# list currently installed components
def list_components
    @installed.each do |comp|
        puts "  #{comp}"
    end
end

run_app