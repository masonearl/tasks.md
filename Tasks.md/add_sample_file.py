import subprocess
import sys

# Add the file to the Xcode project
result = subprocess.run([
    'ruby', '-e',
    '''
    require "xcodeproj"
    project_path = "Tasks.md.xcodeproj"
    project = Xcodeproj::Project.open(project_path)
    
    # Get the main target
    target = project.targets.first
    
    # Add the file reference
    file_ref = project.main_group.new_file("Tasks.md/sample_tasks.md")
    
    # Add to resources build phase
    target.resources_build_phase.add_file_reference(file_ref)
    
    project.save
    puts "✅ Added sample_tasks.md to project"
    '''
], capture_output=True, text=True)

print(result.stdout)
if result.returncode != 0:
    print(result.stderr, file=sys.stderr)
    sys.exit(result.returncode)
